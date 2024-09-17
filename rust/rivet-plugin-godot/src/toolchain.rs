use godot::prelude::*;

use crate::util::runtime;

#[derive(GodotClass)]
#[class(no_init)]
pub struct RivetToolchain {}

#[godot_api]
impl RivetToolchain {
    #[func]
    fn setup() {
        runtime::setup();
    }

    #[func]
    fn shutdown() {
        runtime::shutdown();
    }
}
