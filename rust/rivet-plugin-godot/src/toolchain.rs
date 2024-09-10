use std::sync::mpsc;
use godot::prelude::*;
use toolchain::util::task;

use crate::util::runtime;

#[derive(GodotClass)]
#[class(base=RefCounted)]
pub struct RivetToolchain {
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for RivetToolchain {
    fn init(base: Base<RefCounted>) -> Self {
        Self { base }
    }
}

#[godot_api]
impl RivetToolchain {
    #[func]
    fn setup(&mut self) {
        runtime::setup();
    }

    #[func]
    fn shutdown(&mut self) {
        runtime::shutdown();
    }

    #[func]
    fn run_task(&mut self, name: String, input_json: String, on_output_event: Callable) {
        // TODO: Add aborter

        let (output_tx, output_rx) = mpsc::channel();

        // Run the task
        runtime::spawn(Box::pin(async move {
            let (run_config, mut handles) = task::RunConfig::build();

            // Spawn task
            tokio::task::spawn(async move {
                toolchain::tasks::run_task_json(run_config, &name, &input_json).await
            });

            // Pass events to the sync context
            while let Some(event) = handles.event_rx.recv().await {
                match output_tx.send(event) {
                    Ok(_) => {}
                    Err(_) => {
                        // Abort on receiver dropped
                        break;
                    }
                }
            }
        }));

        // Pass events to Godot callable
        while let Ok(event) = output_rx.recv() {
            // Serialize event
            let event_json = match serde_json::to_string(&event) {
                Ok(x) => x,
                Err(err) => {
                    eprintln!("error with event: {err:?}");
                    return;
                }
            };

            // Call Godot
            on_output_event.callv(godot::builtin::array![Variant::from(event_json)]);
        }
    }

}
