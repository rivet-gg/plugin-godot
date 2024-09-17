use std::fmt::Display;

use godot::{
    classes::EditorInterface,
    global::{print, push_error, push_warning},
    prelude::*,
};

fn logging_enabled() -> bool {
    EditorInterface::singleton()
        .get_editor_settings()
        .expect("get_editor_settings")
        .get_setting("rivet/debug_logs".into())
        .try_to::<bool>()
        .unwrap_or(false)
}

pub fn log(x: impl Display) {
    if logging_enabled() {
        print(&[format!("[Rivet] {x}").to_variant()]);
    }
}

pub fn warning(x: impl Display) {
    push_warning(&[format!("[Rivet] {x}").to_variant()]);
}

pub fn error(x: impl Display) {
    push_error(&[format!("[Rivet] {x}").to_variant()]);
}
