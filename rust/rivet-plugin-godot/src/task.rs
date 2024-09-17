use godot::{
    classes::{Json, Script},
    prelude::*,
};
use tokio::sync::mpsc;
use toolchain::util::task;

use crate::util::{log, runtime};

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
        let input_json = Json::stringify(self.input.clone()).to_string();
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
                        plugin.set("local_backend_port".into(), backend_port.to_variant());
                        plugin.set("local_editor_port".into(), editor_port.to_variant());

                        let mut plugin_bridge_instance = get_plugin_bridge_script()
                            .get("instance".into())
                            .to::<Gd<Object>>();
                        plugin_bridge_instance.call("save_configuration".into(), &[]);

                        log::log(format!(
                            "Port update: backend={backend_port} editor={editor_port}"
                        ));
                    }
                    task::TaskEvent::BackendConfigUpdate(event) => {
                        let godot_event = serde_to_godot(&event);

                        let mut plugin = get_plugin();
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
