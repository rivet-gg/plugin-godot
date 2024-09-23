#!/usr/bin/env -S deno run -A

import { copy } from "jsr:@std/fs";
import { resolve } from "jsr:@std/path";
import { assert } from "jsr:@std/assert";
import { S3Bucket } from "https://deno.land/x/s3@0.5.0/mod.ts";

function getRequiredEnvVar(name: string): string {
    const value = Deno.env.get(name);
    if (!value) {
        throw new Error(`Required environment variable ${name} is not set`);
    }
    return value;
}

const assetVersion = getRequiredEnvVar("ASSET_VERSION");
const awsAccessKeyId = getRequiredEnvVar("AWS_ACCESS_KEY_ID");
const awsSecretAccessKey = getRequiredEnvVar("AWS_SECRET_ACCESS_KEY");
const username = getRequiredEnvVar("GODOT_ASSET_LIB_USERNAME");
const password = getRequiredEnvVar("GODOT_ASSET_LIB_PASSWORD");

assert(/^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/.test(assetVersion), "ASSET_VERSION must be a valid semantic version starting with 'v'");

const REPO_DIR = resolve(import.meta.dirname!, "..");
const OUTPUT_DIR = Deno.env.get("OUTPUT_DIR") ?? await Deno.makeTempDir({ prefix: "rivet-plugin-godot-" });
console.log("Work dir:", OUTPUT_DIR);
const TEMP_DIR = resolve(OUTPUT_DIR, "rivet-plugin-godot");
const ZIP_PATH = resolve(OUTPUT_DIR, "rivet-plugin-godot.zip");

async function buildCrossPlatform() {
    // We build this in the repo dir in order to make sure we use the build cache
    console.log("Building cross-platform binaries");
    const buildOutput = await (new Deno.Command(resolve(REPO_DIR, "scripts", "build_cross.sh"), {
        cwd: REPO_DIR,
        stdout: "inherit",
        stderr: "inherit",
    })).output();
    assert(buildOutput.success, "Failed to build cross-platform binaries");
}

async function copyFilesToTemp() {
    console.log("Copying files to temp directory");
    await copy(REPO_DIR, TEMP_DIR, { overwrite: true });
}

async function removeUnnecessaryFiles() {
    console.log("Removing unnecessary files...");
    for await (const entry of Deno.readDir(TEMP_DIR)) {
        const path = resolve(TEMP_DIR, entry.name);
        if (entry.name !== "addons" && entry.name !== "LICENSE") {
            if (entry.isDirectory) {
                await Deno.remove(path, { recursive: true });
            } else {
                await Deno.remove(path);
            }
        }
    }
}

async function templateFiles() {
  const pluginCfgPath = resolve(TEMP_DIR, "addons", "rivet", "plugin.cfg");
  const pluginCfg = await Deno.readTextFile(pluginCfgPath);
  await Deno.writeTextFile(pluginCfgPath, pluginCfg.replace("{{VERSION}}", assetVersion.slice(1)));
}

async function generateZipFile() {
    console.log("Generating zip file");
    const zipOutput = await (new Deno.Command("zip", {
        args: ["-r", ZIP_PATH, "."],
        cwd: TEMP_DIR,
        stdout: "inherit",
        stderr: "inherit",
    })).output();
    assert(zipOutput.success, "Failed to create zip");
    console.log(`Zip file created: ${ZIP_PATH}`);
}

async function uploadZipToS3(): Promise<{ zipUrl: string; iconUrl: string }> {
    console.log("Uploading zip file and icon to S3");
    const bucket = new S3Bucket({
        accessKeyID: awsAccessKeyId,
        secretKey: awsSecretAccessKey,
        bucket: "rivet-releases",
        region: "auto",
        endpointURL: "https://2a94c6a0ced8d35ea63cddc86c2681e7.r2.cloudflarestorage.com/rivet-releases",
    });

    const zipObjectKey = `plugin-godot/${assetVersion}/rivet-plugin-godot.zip`;
    const iconObjectKey = `plugin-godot/${assetVersion}/icon.png`;

    const zipFileData = await Deno.readFile(ZIP_PATH);
    const iconFileData = await Deno.readFile(resolve(REPO_DIR, "media", "icon.png"));

    await bucket.putObject(zipObjectKey, zipFileData);
    await bucket.putObject(iconObjectKey, iconFileData);

    console.log(`Uploaded zip file to S3: ${zipObjectKey}`);
    console.log(`Uploaded icon file to S3: ${iconObjectKey}`);

    return {
        zipUrl: `https://releases.rivet.gg/${zipObjectKey}`,
        iconUrl: `https://releases.rivet.gg/${iconObjectKey}`,
    };
}

async function generateAssetConfig(downloadUrl: string, iconUrl: string) {
    console.log("Generating asset template");

    // We have to use the S3 upload instead of raw GitHub download since we need
    // to build the toolchain. The same applies for the icon.
    return {
        "title": "Rivet - Multiplayer Tooling, Game Servers, & Backend (Open-Source & Self-Hostable)",
        "description": await Deno.readTextFile(
            resolve(REPO_DIR, "media", "asset-lib", "description.txt"),
        ),
        "category_id": "6",
        "godot_version": "4.2",
        "version_string": assetVersion,
        "cost": "Apache-2.0",
        "download_provider": "Custom",
        "download_commit": downloadUrl,
        "browse_url": "https://github.com/rivet-gg/rivet",
        "issues_url": "https://github.com/rivet-gg/rivet/issues",
        "icon_url": iconUrl,
    };
}

async function submitToGodotAssetStore(assetConfig: any): Promise<string> {
    console.log(`Submitting asset:\n${JSON.stringify(assetConfig, null, 2)}`);

    const baseUrl = "https://godotengine.org/asset-library/api";
    const assetId = "1881";

    // Login
    console.log(`Logging in as ${username}`);
    const loginResponse = await fetch(`${baseUrl}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
    });

    if (!loginResponse.ok) {
        throw new Error(`Login failed: ${await loginResponse.text()}`);
    }

    const { token } = await loginResponse.json();

    try {
        // Submit asset edit
        console.log("Submitting asset edit");
        const submitResponse = await fetch(`${baseUrl}/asset/${assetId}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ ...assetConfig, token }),
        });
        if (!submitResponse.ok) {
            throw new Error(`Asset submission failed: ${await submitResponse.text()}`);
        }

        const { id: assetEditId } = await submitResponse.json();
        console.log(`Asset edit submitted. Edit ID: ${assetEditId}`);

        return assetEditId;
    } finally {
        // Logout
        console.log("Logging out of asset lib");
        await fetch(`${baseUrl}/logout`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ token }),
        });
    }
}

async function main() {
    await buildCrossPlatform();
    await copyFilesToTemp();
    await removeUnnecessaryFiles();
    await templateFiles();
    await generateZipFile();
    const { zipUrl, iconUrl } = await uploadZipToS3();
    const assetConfig = await generateAssetConfig(zipUrl, iconUrl);
    const assetEditId = await submitToGodotAssetStore(assetConfig);
    console.log(`Asset submission complete. Edit ID: ${assetEditId}`);
}

if (import.meta.main) {
    main();
}
