use godot::{classes::Json, prelude::*};

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
    fn run_task(
        &mut self,
        run_config: Dictionary,
        name: String,
        input_variant: Variant,
    ) -> Variant {
        let input_json = Json::stringify(input_variant).to_string();

        godot_print!("[Rivet] [Task] {name} Input: {input_json}");

        let task_config = toolchain::tasks::get_task_config(&name);

        let run_config = toolchain::tasks::RunConfig {
            abort_path: run_config.at("abort_path").to(),
            output_path: run_config.at("output_path").to(),
        };

        let name_inner = name.clone();
        let output_json = block_on(
            async move { toolchain::tasks::run_task_json(run_config, &name_inner, &input_json).await },
            BlockOnOpts {
                multithreaded: task_config.prefer_multithreaded,
            },
        );

        godot_print!("[Rivet] [Task] {name} Output: {output_json}");

        let output_variant = Json::parse_string(output_json.into());
        output_variant
    }
}
