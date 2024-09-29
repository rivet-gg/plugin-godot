use std::path::Path;

use godot::{
    classes::{object::ConnectFlags, EditorInterface, Json, ProjectSettings, Script},
    prelude::*,
};
use tokio::sync::mpsc;
use toolchain::util::task;

use crate::util::{log, runtime};

const RIVET_SDK_SINGLETON_NAME: &str = "Rivet";

#[derive(GodotClass)]
#[class(tool, no_init, base = Node)]
pub struct RivetTask {
    base: Base<Node>,

    name: String,
    input: Variant,

    /// If the task has been started.
    is_started: bool,

    /// If `kill` has been called.
    is_killed: bool,

    /// If the `event_tx` channel has closed.
    is_running: bool,

    /// Handles used to control the task.
    handles: Option<task::RunHandles>,

    /// Store result in order to be accessed from `on_finish`.
    result_event: Option<Dictionary>,
}

#[godot_api]
impl RivetTask {
    #[signal]
    fn task_log(logs: Variant, type_: Variant) {}

    #[signal]
    fn task_ok(ok: Variant) {}

    #[signal]
    fn task_error(error: Variant) {}

    #[signal]
    fn task_output(output: Variant) {}

    #[func]
    fn with_name_input(name: String, input: Variant) -> Option<Gd<Self>> {
        if name.is_empty() || input.is_nil() {
            log::error("RivetTask initiated without required args");
            return None;
        }

        Some(Gd::from_init_fn(|base| Self {
            base,
            name,
            input,
            is_started: false,
            is_killed: false,
            is_running: false,
            handles: None,
            result_event: None,
        }))
    }

    #[func]
    fn start(&mut self) {
        if self.is_started {
            log::warning(format!("[{}] Task already started", self.name));
            return;
        }
        if !self.base().is_inside_tree() {
            log::error("need to add RivetTask to the tree before calling start()");
            return;
        }

        // Serialize input
        let input_json = Json::stringify(&self.input.clone()).to_string();
        log::log(format!("[{}] Request: {input_json}", self.name));

        // Setup task
        let (run_config, handles) = task::RunConfig::build();
        self.handles = Some(handles);

        // Spawn task
        {
            let name = self.name.clone();
            runtime::spawn(Box::pin(async move {
                toolchain::tasks::run_task_json(run_config, &name, &input_json).await;
            }));
        }

        self.is_started = true;
        self.is_running = true;
    }

    fn on_finish(&mut self) {
        self.is_running = false;

        let output_result = if self.is_killed {
            dict! {
                "Err": "Task killed"
            }
        } else if let Some(log_result) = self.result_event.clone() {
            log_result
        } else {
            log::error("Received no output from task");
            dict! {
                "Err": "Received no output from task"
            }
        };

        self.base_mut()
            .emit_signal("task_output".into(), &[output_result.to_variant()]);

        if let Some(ok_value) = output_result.get("Ok") {
            log::log(format!("[{}] Success: {}", self.name, ok_value.to_string()));
            self.base_mut().emit_signal("task_ok".into(), &[ok_value]);
        } else if let Some(err_value) = output_result.get("Err") {
            log::warning(format!("[{}] Error: {}", self.name, err_value.to_string()));
            self.base_mut()
                .emit_signal("task_error".into(), &[err_value]);
        } else {
            log::error(format!("[{}] Result does not have Ok or Err", self.name));
        }

        self.base_mut().queue_free();
    }

    #[func]
    fn kill(&mut self) {
        if !self.is_running || self.is_killed {
            return;
        }

        self.is_killed = true;

        // Send kill to task
        let Some(handles) = self.handles.as_mut() else {
            return;
        };
        let abort_tx = handles.abort_tx.clone();
        runtime::spawn(Box::pin(async move {
            if abort_tx.send(()).await.is_err() {
                log::error(format!("Task abort receiver dropped"));
            }
        }));
    }
}

#[godot_api]
impl INode for RivetTask {
    fn process(&mut self, _delta: f64) {
        if !self.is_started {
            log::warning(format!(
                "called RivetTask.process on task that's not started"
            ));
            return;
        }
        if !self.is_running {
            log::warning(format!(
                "called RivetTask.process on task that's not running"
            ));
            return;
        }

        loop {
            let Some(handles) = self.handles.as_mut() else {
                log::warning(format!("called RivetTask.process without handles"));
                return;
            };
            match handles.event_rx.try_recv() {
                Ok(event) => match event {
                    task::TaskEvent::Log(log) => {
                        self.base_mut()
                            .emit_signal("task_log".into(), &[log.to_variant(), 0.to_variant()]);
                    }
                    task::TaskEvent::Result { result } => {
                        // Parse result to JSON
                        let json = Json::parse_string(result.get().into());
                        match json.try_to::<Dictionary>() {
                            Ok(x) => {
                                // Save for use in `on_finish`
                                self.result_event = Some(x);
                            }
                            Err(err) => {
                                log::error(format!(
                                    "[{}] Failed to convert result: {err}",
                                    self.name
                                ));
                                self.is_running = false;
                                self.base_mut().queue_free();
                                return;
                            }
                        };
                    }
                    task::TaskEvent::PortUpdate {
                        backend_port,
                        editor_port,
                    } => {
                        let mut plugin = get_plugin();

                        // Set value
                        plugin.set("local_backend_port".into(), &backend_port.to_variant());
                        plugin.set("local_editor_port".into(), &editor_port.to_variant());

                        // Publish event
                        let mut plugin_bridge_instance = get_plugin_bridge_script()
                            .get("instance".into())
                            .to::<Gd<Object>>();
                        plugin_bridge_instance.call("save_configuration".into(), &[]);

                        log::log(format!(
                            "Port update: backend={backend_port} editor={editor_port}"
                        ));
                    }
                    task::TaskEvent::BackendConfigUpdate(event) => {
                        let mut plugin = get_plugin();

                        let godot_event = serde_to_godot(&event);

                        // Scan for new SDK & add autoload automatically
                        if let Some(sdk) = event.sdks.iter().find(|x| x.target == "godot") {
                            // Validate SDK exists
                            let sdk_exists = match std::fs::metadata(&sdk.output) {
                                Ok(x) => x.is_dir(),
                                Err(_) => false,
                            };
                            if sdk_exists {
                                // Reload file tree, since Godot usually doesn't pick up on this file
                                // automatically
                                let absolute_autoload_path = Path::new(&sdk.output)
                                    .join("rivet.gd")
                                    .display()
                                    .to_string();
                                let local_autoload_path = ProjectSettings::singleton()
                                    .localize_path(absolute_autoload_path.into())
                                    .to_string();

                                // Add autoload on file change
                                log::log("Reloading file system to scan for new SDK");
                                let mut resource_filesystem = EditorInterface::singleton()
                                    .get_resource_filesystem()
                                    .expect("get_resource_filesystem");
                                resource_filesystem
                                .connect_ex(
                                    "sources_changed".into(),
                                    Callable::from_fn("add_rivet_sdk_autoload", move |_| {
                                        log::log("File system scan from SDK update complete, adding autoload");

                                        // Add autoload (this is idempotent)
                                        let mut plugin = get_plugin();
                                        plugin.emit_signal(
                                            "add_autoload".into(),
                                            &[
                                                RIVET_SDK_SINGLETON_NAME.to_variant(),
                                                local_autoload_path.to_variant(),
                                            ],
                                        );

                                        // Notify SDK updated
                                        plugin.set("backend_sdk_exists".into(), &true.to_variant());
                                        plugin.emit_signal("backend_sdk_update".into(), &[]);

                                        // TODO: Figure out how to emulate clearing the console
                                        // // Clear the output since there will be a benign script
                                        // // load error before the singleton is activated
                                        // plugin.call("trigger_input_action".into(), &["editor/clear_output".to_variant()]);

                                        Ok(Variant::nil())
                                    }),
                                )
                                .flags(ConnectFlags::ONE_SHOT.ord() as u32)
                                .done();

                                // Re-scan file system for new SDk
                                resource_filesystem.scan();
                            } else {
                                log::log("SDK does not exist yet");
                            }
                        }

                        // Publish event
                        plugin.emit_signal("backend_config_update".into(), &[godot_event]);

                        log::log(format!("Backend config update"));
                    }
                },
                Err(mpsc::error::TryRecvError::Empty) => {
                    // No more messages
                    break;
                }
                Err(mpsc::error::TryRecvError::Disconnected) => {
                    // Shutdown
                    self.on_finish();
                    break;
                }
            }
        }
    }
}

fn get_plugin_bridge_script() -> Gd<Script> {
    load::<Script>("res://addons/rivet/rivet_plugin_bridge.gd")
}

fn get_plugin() -> Gd<Object> {
    get_plugin_bridge_script()
        .call("get_plugin".into(), &[])
        .to::<Gd<Object>>()
}

fn serde_to_godot(value: &impl serde::Serialize) -> Variant {
    let json_str = serde_json::to_string(value).expect("stringify backend config event");
    Json::parse_string(json_str.into())
}
