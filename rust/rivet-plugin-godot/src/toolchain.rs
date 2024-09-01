use godot::prelude::*;
use tokio::task::block_in_place;
use toolchain::util::task;

use crate::util::runtime::{block_on, BlockOnOpts};

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
    fn run_task(&mut self, name: String, input_json: String, on_output_event: Callable) {
        let name_inner = name.clone();
        block_on(
            async move {
                let (run_config, mut handles) = task::RunConfig::build();

                // TODO: Add aborter

                // Spawn task
                tokio::task::spawn(async move {
                    toolchain::tasks::run_task_json(run_config, &name_inner, &input_json).await
                });

                // Pass events to Godot
                //
                // Do this in the current thread since `Callable` is not `Send`
                while let Some(event) = handles.event_rx.recv().await {
                    block_in_place(|| {
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
                    });
                }
            },
            BlockOnOpts {},
        );
    }
}
