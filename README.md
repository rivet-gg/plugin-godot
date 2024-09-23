<p align="center">
	<picture>
		<source media="(prefers-color-scheme: dark)" srcset="./addons/rivet/images/icon-text-white.svg">
		<img src="./addons/rivet/images/icon-text-black.svg">
	</picture>
</p>
<h1 align="center">Rivet Godot 4 Plugin</h1>
<p align="center">
	<a href="https://rivet.gg/discord"><img src="https://img.shields.io/discord/822914074136018994"></a>
</p>

---

## 📦 Installation

### Godot Asset Library

1. Within your Godot project, click _Asset Library_
2. Search for "Rivet"
3. Install the plugin
4. Support the project by giving the [Rivet GitHub repo](https://github.com/rivet-gg/rivet) a star.

### Manual installation

1. [Download and unpack the latest release](https://github.com/rivet-gg/plugin-godot/releases/latest)
2. Copy the `plugin-godot/addons/rivet` folder to `your-godot-project/addons/rivet`.
3. Enable this addon within the Godot settings
   `Project > Project Settings > Plugins`
4. Support the project by giving the [Rivet GitHub repo](https://github.com/rivet-gg/rivet) a star.

### Using [`gd-plug`](https://github.com/imjp94/gd-plug)

1. Add this line to your `plug.gd`:

```gdscript
plug("rivet/plugin-godot")
```
2. Support the project by giving the [Rivet GitHub repo](https://github.com/rivet-gg/rivet) a star.

### Build from source

1. Ensure the prerequisites are installed:
    - Git LFS
    - Rust
    - Deno
2. Clone this repository
3. Build with `deno run -A scripts/build_dev.ts`
4. Copy the `plugin-godot/addons/rivet` folder to `your-godot-project/addons/rivet`.
5. Enable this addon within the Godot settings
   `Project > Project Settings > Plugins`
6. Support the project by giving the [Rivet GitHub repo](https://github.com/rivet-gg/rivet) a star.

## 🚀 Getting started

Head over to our [Documentation](https://rivet.gg/docs/godot) to get started with Rivet and Godot.

## 🏗️ Contributing

1. Look for any issue that describes something that needs to be done - or, if
   you're willing to add a new feature, create a new issue with an appropriate
   description.
2. Submit your pull request.
3. Rivet team will review your changes.
4. Join [Rivet's Discord](https://rivet.gg/discord) to ask questions & showcase your game.

## 📷 Examples

Each folder in the `examples/` folder is its own independent Godot project.

See _Enabling support for symbolic links on Windows_ below.

## Troubleshooting

### Enabling support for symbolic links on Windows

_Only relevant for testing examples._

This repository relies on use of symbolic links in order to re-use the `addons/rivet/` folder inside of `examples/*/addons/rivet/`.

If you don't files in the folder `examples/*/addons/rivet/`, do the following:

**Enable developer mode**

1. Open _Settings_
2. Navigate to _Updates & Security > For Developers_
3. Enable _Developer Mode_

    <img src="./media/readme/windows-developer-mode.png" width="600" alt="Developer mode">

**Enable symlinks in Git**

1. Delete the `plugin-godot` folder
2. Download and run the Git installer (even if Git is already installed)
3. Uncheck _Only show new options_ at the bottom of the window
4. Click _Next_ until you see the _Configuring extra options_ screen
5. Check _Enable symbolic links_
6. Finish the installation
7. Re-clone the repository. You should see files under `examples/*/addons/rivet/`.

    <img src="./media/readme/windows-symlinks.png" width="600" alt="Symbolic link">

