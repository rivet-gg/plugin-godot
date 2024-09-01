#!/bin/sh

cargo build --manifest-path rust/Cargo.toml
mkdir -p addons/rivet/native/debug/
cp rust/target/debug/librivet_plugin_godot.dylib addons/rivet/native/debug/librivet_plugin_godot_macos_arm64.dylib

