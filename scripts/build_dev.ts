#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read --allow-write --allow-run

import { ensureDir } from "jsr:@std/fs";
import { dirname, fromFileUrl, join } from "jsr:@std/path";

const __dirname = dirname(fromFileUrl(Deno.mainModule));

const platform = Deno.build.os;
const arch = Deno.build.arch;

let targetDir;
let libName;
let rustLibName;

if (platform === "linux" && arch === "x86_64") {
  targetDir = "x86_64-unknown-linux-gnu";
  libName = "librivet_plugin_godot_linux_x86_64.so";
  rustLibName = "librivet_plugin_godot.so";
} else if (platform === "windows" && arch === "x86_64") {
  targetDir = "x86_64-pc-windows-gnu";
  libName = "librivet_plugin_godot_windows_x86_64.dll";
  rustLibName = "rivet_plugin_godot.dll";
} else if (platform === "darwin" && arch === "x86_64") {
  targetDir = "x86_64-apple-darwin";
  libName = "librivet_plugin_godot_macos_x86_64.dylib";
  rustLibName = "librivet_plugin_godot.dylib";
} else if (platform === "darwin" && arch === "aarch64") {
  targetDir = "aarch64-apple-darwin";
  libName = "librivet_plugin_godot_macos_arm64.dylib";
  rustLibName = "librivet_plugin_godot.dylib";
} else {
  console.error(`Unsupported platform: ${platform}-${arch}`);
  Deno.exit(1);
}

const buildCmd = new Deno.Command("cargo", {
  args: [
    "build",
    "--manifest-path",
    join(__dirname, "..", "rust", "Cargo.toml"),
  ],
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
});

console.log(`Building for ${platform}-${arch}...`);
const buildOutput = await buildCmd.output();

if (buildOutput.success) {
  console.log("Build successful");
} else {
  console.error("Build failed");
  Deno.exit(1);
}

const rustTargetPath = join(
  __dirname,
  "..",
  "rust",
  "target",
  "debug",
  rustLibName,
);
const godotNativePath = join(
  __dirname,
  "..",
  "addons",
  "rivet",
  "native",
  "debug",
  libName,
);

console.log(`Copying ${rustTargetPath} to ${godotNativePath}`);
try {
  await ensureDir(dirname(godotNativePath));
  await Deno.copyFile(rustTargetPath, godotNativePath);
  console.log("Copy successful!");
} catch (err) {
  console.error("Copy failed:");
  console.error(err);
  Deno.exit(1);
}
