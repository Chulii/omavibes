# OmaVibes: Type with Cozy Sound

Mechanical keyboard sound effects with 29 different soundpacks, search, random playback, and volume control for the Omarchy bar.

---

<img width="1536" height="1024" alt="preview" src="https://github.com/user-attachments/assets/ce817e0f-87d0-48ce-8689-35115b2382ec" />
<img width="1899" height="1080" alt="preview1" src="https://github.com/user-attachments/assets/288f805b-8436-4ba8-bb2f-b9d572ca87c1" />

<https://github.com/user-attachments/assets/c6a59ad7-b5af-4149-bff5-a7361f42ecd2>

`Note: Enable sound in the above preview video`

---
> I didn't originally plan on releasing this.
>
> I created OmaVibes because I wanted those thocky, creamy mechanical keyboard sounds while typing, but I couldn't afford a mechanical keyboard sound setup. So I decided to build my own solution.
>
> OmaVibes originally started with a Walker-based implementation, and eventually evolved into an Omarchy plugin with a proper bar interface, soundpack browser, search, random playback, per-pack volume control, and persistent settings.
>
> Hopefully you enjoy it.

## What is OmaVibes?

OmaVibes is an Omarchy bar widget that lets you play keyboard sound effects while typing.
It uses **wayvibes**, a keyboard sound runtime that plays sounds in response to keyboard input. OmaVibes bundles the runtime, so users do **not** need to install wayvibes separately.

---

## Features

* **Omarchy bar integration** — Open OmaVibes directly from the top bar.
* **29 bundled soundpacks** — A collection of mechanical keyboard and novelty sound effects.
* **Soundpack browser** — Browse all available sounds from one panel.
* **Search** — Filter soundpacks instantly by name.
* **Keyboard navigation** — After searching, use **↑ / ↓** to move through matching soundpacks and **Enter** to play the highlighted pack.
* **One-click playback** — Select a soundpack to start playing it immediately.
* **Random playback** — Pick a random soundpack from the available collection.
* **Turn Off** — Stop the currently playing keyboard sounds.
* **Volume control** — Adjust the volume from 1 to 10.
* **Per-pack volume** — Each soundpack remembers its own volume setting.
* **Persistent settings** — Soundpack and volume settings are preserved across shell restarts.
* **Search reset on close** — Closing the panel clears the current search, so reopening starts with the full pack list.
* **Theme-aware interface** — Uses Omarchy/Quickshell styling and the active bar font.
* **Bundled runtime** — Includes the `wayvibes` executable and bundled soundpacks, so a separate wayvibes installation is not required.

---

## Requirements

* **Omarchy 4 (Quattro)**
* A working Quickshell-based Omarchy shell
* Keyboard input access for the bundled `wayvibes` runtime
* `libevdev` available on the system for the bundled runtime

### Keyboard Input Access

Depending on your system configuration, `wayvibes` may require your user to be part of the `input` group:

```bash
sudo usermod -aG input $USER
```

Log out and back in after changing the group.

---

## Installation

### From the Omarchy Plugin Marketplace

After OmaVibes is published:

```bash
omarchy plugin add https://github.com/mshareef-git/omavibes.git --enable
```

### From GitHub

Clone the repository into the Omarchy plugin directory:

```bash
git clone https://github.com/mshareef-git/omavibes.git \
  ~/.config/omarchy/plugins/io.github.mshareef-git.omavibes
```

Validate the plugin:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/io.github.mshareef-git.omavibes
```

Enable the plugin:

```bash
omarchy plugin enable io.github.mshareef-git.omavibes right
```

Restart the shell if necessary:

```bash
omarchy restart shell
```

---

## Usage

Click the OmaVibes keyboard icon in the Omarchy top bar.

### Search

Use the search field to filter the available soundpacks by name.

When results are shown:

* **↓** moves the keyboard highlight down.
* **↑** moves the keyboard highlight up.
* **Enter** plays the highlighted soundpack.

The first matching soundpack is selected automatically when a search is entered or changed.

### Play a Soundpack

Click any soundpack in the list to start playing it.

The currently playing soundpack is highlighted and marked with a check.

### Random

Click **Random** to choose a random soundpack.

When a search is active, random playback uses the currently filtered soundpacks.

### Turn Off

Click **Turn Off** to stop the currently playing keyboard sounds.

### Volume

Use the volume slider to adjust the current soundpack's volume from 1 to 10.

Each soundpack can have its own saved volume level.

---

## Soundpacks

OmaVibes includes **29 bundled soundpacks** inside the `packs/` directory. The bundled collection includes mechanical keyboard packs as well as novelty packs such as **Chalks**, **Thocks**, **Farts**, and **Press**.

The soundpacks are included with the plugin so OmaVibes works immediately after installation without requiring users to download additional soundpacks.

### Custom Soundpacks

OmaVibes also supports user soundpacks through:

```text
~/wayvibes/<pack-name>/
```

A custom soundpack can contain the audio files required by `wayvibes` together with its `config.json`.

When a matching user soundpack exists, OmaVibes can use the user version instead of the bundled version.

---

## How It Works

OmaVibes is implemented as an Omarchy bar widget using Quickshell.

```text
BarWidget.qml
    |
    +-- Panel.qml
          |
          +-- OmaVibesState.qml
                  |
                  +-- Soundpack selection
                  +-- Search and keyboard navigation
                  +-- Random playback
                  +-- Volume control
                  +-- Persistent settings
                  +-- wayvibes process control
```

The bundled `wayvibes` executable is located at:

```text
bin/wayvibes
```

Bundled soundpacks are located at:

```text
packs/
```

OmaVibes stores its persistent state at:

```text
~/.local/state/omarchy/omavibes.json
```

---

## Bundled Wayvibes Runtime

OmaVibes intentionally bundles `wayvibes` so users do not need to install a separate Wayvibes package.

The bundled runtime is based on the upstream Wayvibes project:

* Repository: <https://github.com/sahaj-b/wayvibes>
* Pinned source commit: `7c70a5a2bf4c7b071eaa6e6e86cfb0c72fb84a5a`
* Build recipe: the upstream `Makefile`
* Rebuild script: `third_party/wayvibes/build.sh`
* Source snapshot: `third_party/wayvibes/`
* Bundled binary: `bin/wayvibes`
* Current bundled binary SHA-256:
  `b4b2d4c8682e161cc2694b74301d587b1b9bd2210b0fa0fc35aed71c6e2f2352`

The vendored source snapshot and build metadata are included so the bundled runtime has a clear upstream source and build provenance.

The bundled binary is built against the system's `libevdev` library. A separate Wayvibes installation is not required.

---

## Repository Structure

```text
omavibes/
├── BarWidget.qml
├── Panel.qml
├── OmaVibesState.qml
├── manifest.json
├── qmldir
├── README.md
├── LICENSE
├── preview.png
├── bin/
│   └── wayvibes
├── packs/
│   └── <soundpacks>/
└── third_party/
    └── wayvibes/
        ├── Makefile
        ├── SOURCE_COMMIT
        ├── build.sh
        └── src/
```

---

## Development

From the plugin directory, validate the plugin with:

```bash
omarchy plugin validate .
```

Run QML linting against the Omarchy shell:

```bash
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml \
  Panel.qml \
  OmaVibesState.qml
```

### Rebuild the Bundled Wayvibes Runtime

From the plugin root:

```bash
./third_party/wayvibes/build.sh
```

The script rebuilds `bin/wayvibes` from the vendored, pinned Wayvibes source.

After making changes, restart the Omarchy shell:

```bash
omarchy restart shell
```

### Before Publishing

Test the following:

* Bar icon appears correctly
* Panel opens and closes correctly
* Search filtering works
* ↑ / ↓ keyboard navigation works
* Enter plays the highlighted soundpack
* Closing the panel clears the search
* Soundpack selection works
* Random playback works
* Turn Off works
* Volume control works
* Per-pack volume is preserved
* Bundled Wayvibes runtime works
* Bundled and custom soundpacks work
* Shell restart does not break the plugin
* Plugin can be disabled and enabled again
* Plugin can be removed cleanly
* `omarchy plugin validate .` passes

---

## Removal

Disable the plugin:

```bash
omarchy plugin disable io.github.mshareef-git.omavibes
```

Remove the plugin:

```bash
omarchy plugin remove io.github.mshareef-git.omavibes
```

Removing the plugin does not remove user data stored outside the plugin directory, such as:

```text
~/.local/state/omarchy/omavibes.json
~/wayvibes/
```

These can be removed separately if no longer needed.

---

## Credits

Built for Omarchy Quattro.

Wayvibes:
<https://github.com/sahaj-b/wayvibes>

Omarchy:
<https://omarchy.org/>

---

## License

OmaVibes is licensed under the MIT License.

See `LICENSE` for the complete license text.
