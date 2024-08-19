#!/bin/sh

mkdir -p addons/rivet/cli
mkdir -p addons/rivet/native/release
mkdir -p addons/rivet/native/debug

# Linux (x86_64)
cp $CLI_REPO_PATH/target/x86_64-unknown-linux-gnu/release/rivet addons/rivet/cli/rivet_linux
# cp rust/target/x86_64-unknown-linux-gnu/release/librivet_plugin_godot.so addons/rivet/native/release/librivet_plugin_godot_linux_x86_64.so
# cp rust/target/x86_64-unknown-linux-gnu/debug/librivet_plugin_godot.so addons/rivet/native/debug/librivet_plugin_godot_linux_x86_64.so

# Windows (x86_64)
cp $CLI_REPO_PATH/target/x86_64-pc-windows-gnu/release/rivet.exe addons/rivet/cli/rivet_windows.exe
# cp rust/target/x86_64-pc-windows-gnu/release/rivet_plugin_godot.dll addons/rivet/native/release/librivet_plugin_godot_windows_x86_64.dll
# cp rust/target/x86_64-pc-windows-gnu/debug/rivet_plugin_godot.dll addons/rivet/native/debug/librivet_plugin_godot_windows_x86_64.dll

# macOS (x86_64)
cp $CLI_REPO_PATH/target/x86_64-apple-darwin/release/rivet addons/rivet/cli/rivet_x86_apple
# cp rust/target/x86_64-apple-darwin/release/librivet_plugin_godot.dylib addons/rivet/native/release/librivet_plugin_godot_macos_x86_64.dylib
# cp rust/target/x86_64-apple-darwin/debug/librivet_plugin_godot.dylib addons/rivet/native/debug/librivet_plugin_godot_macos_x86_64.dylib

# macOS (ARM64)
cp $CLI_REPO_PATH/target/aarch64-apple-darwin/release/rivet addons/rivet/cli/rivet_aarch64_apple
# cp rust/target/aarch64-apple-darwin/release/librivet_plugin_godot.dylib addons/rivet/native/release/librivet_plugin_godot_macos_arm64.dylib
# cp rust/target/aarch64-apple-darwin/debug/librivet_plugin_godot.dylib addons/rivet/native/debug/librivet_plugin_godot_macos_arm64.dylib
