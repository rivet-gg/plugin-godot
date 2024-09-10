use godot::prelude::*;
use std::sync::mpsc;
use toolchain::util::task;

use crate::{task_handle::RivetTaskHandle, util::runtime};

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

    // HACK: Ideally return task handle from this instead of using on_start callback. This would require
    // spawning a thread, so unsure if there's a problem calling callables that are moved between
    // threads. This is the safest implementation where we keep callables on the same thread they
    // were called from.
    #[func]
    fn run_task(
        &mut self,
        name: String,
        input_json: String,
        on_start: Callable,
        on_output_event: Callable,
    ) {
        let (output_tx, output_rx) = mpsc::channel();
        let (run_config, mut handles) = task::RunConfig::build();

        // Pass task handle back to Godot
        let task_handle = RivetTaskHandle::create(handles.abort_tx);
        on_start.callv(array![Variant::from(task_handle)]);

        // Run the task
        runtime::spawn(Box::pin(async move {
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

        // Pass events to Godot
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
            on_output_event.callv(array![Variant::from(event_json)]);
        }
    }
}
