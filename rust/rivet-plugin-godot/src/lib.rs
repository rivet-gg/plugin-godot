mod toolchain;
mod util;

use godot::prelude::*;

struct RivetPlugin;

#[gdextension]
unsafe impl ExtensionLibrary for RivetPlugin {}

