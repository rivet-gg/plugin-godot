#!/bin/sh

# cargo build --manifest-path rust/Cargo.toml
mkdir -p addons/rivet/native/debug/
cp rust/target/debug/rivet_plugin_godot.dll addons/rivet/native/debug/librivet_plugin_godot_windows_x86_64.dll
