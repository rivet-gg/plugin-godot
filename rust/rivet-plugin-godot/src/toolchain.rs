use godot::prelude::*;
use toolchain::tasks::RunConfig;

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
    fn run_task(&mut self, run_config: String, name: String, input_json: String) -> String {
        let run_config = serde_json::from_str::<RunConfig>(&run_config).unwrap();

        let task_config = toolchain::tasks::get_task_config(&name);

        let name_inner = name.clone();
        let output_json = block_on(
            async move { toolchain::tasks::run_task_json(run_config, &name_inner, &input_json).await },
            BlockOnOpts {
                multithreaded: task_config.prefer_multithreaded,
            },
        );

        output_json
    }
}
