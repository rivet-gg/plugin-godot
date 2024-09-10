#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read --allow-write --allow-run

import "./build_dev.ts";

import { dirname, fromFileUrl, join } from "jsr:@std/path";

const __dirname = dirname(fromFileUrl(Deno.mainModule));

async function findGodotExecutable(): Promise<string | null> {
  const possiblePaths = [
    "godot",
    "/usr/bin/godot",
    "/usr/local/bin/godot",
    "/Applications/Godot.app/Contents/MacOS/Godot",
    "/Applications/Godot_mono.app/Contents/MacOS/Godot",
    "C:\\Program Files\\Godot\\Godot.exe",
    "C:\\Program Files (x86)\\Godot\\Godot.exe",
  ];

  for (const path of possiblePaths) {
    try {
      const command = new Deno.Command(path, { args: ["--version"] });
      const { success } = await command.output();
      if (success) {
        return path;
      }
    } catch {
      // Ignore errors and continue searching
    }
  }

  return null;
}

async function main() {
  const godotPath = await findGodotExecutable();
  if (!godotPath) {
    console.error("Godot executable not found. Please make sure Godot is installed and in your PATH.");
    Deno.exit(1);
  }

  const projectPath = join(__dirname, "..", "examples", "lobbies_servers");

  const command = new Deno.Command(godotPath, {
    args: ["--editor", "--path", projectPath],
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
  });

  const { code } = await command.output();

  Deno.exit(code);
}

if (import.meta.main) {
  main();
}
