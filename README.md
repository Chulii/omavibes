# OmaVibes: Type with Cozy Sound

Mechanical keyboard sound effects with 25 different soundpacks, search, random playback, and volume control for the Omarchy bar.
---

<img width="1536" height="1024" alt="preview" src="https://github.com/user-attachments/assets/ce817e0f-87d0-48ce-8689-35115b2382ec" />
<img width="1899" height="1080" alt="preview1" src="https://github.com/user-attachments/assets/288f805b-8436-4ba8-bb2f-b9d572ca87c1" />

https://github.com/user-attachments/assets/c6a59ad7-b5af-4149-bff5-a7361f42ecd2

---
> I didn't originally plan on releasing this.
>
> I created OmaVibes because I wanted those thocky, creamy mechanical keyboard sounds while typing, but I couldn't afford a mechanical keyboard sound setup. So I decided to build my own solution.
>
> OmaVibes originally started with a Walker-based implementation, and eventually evolved into an Omarchy plugin with a proper bar interface, soundpack browser, search, random playback, per-pack volume control, and persistent settings.
>
> Hopefully you enjoy it.

## Features

* **Omarchy bar integration** — Open OmaVibes directly from the top bar.
* **25 soundpacks** — A collection of mechanical keyboard sound effects.
* **Soundpack browser** — Browse the available keyboard sounds from one panel.
* **Search** — Filter soundpacks instantly by name.
* **One-click playback** — Select a soundpack to start playing it immediately.
* **Random playback** — Pick a random soundpack from the available collection.
* **Turn Off** — Stop the currently playing keyboard sounds.
* **Volume control** — Adjust the volume from 1 to 10.
* **Per-pack volume** — Each soundpack remembers its own volume setting.
* **Persistent settings** — Soundpack and volume settings are preserved across shell restarts.
* **Theme-aware interface** — Uses Omarchy/Quickshell styling and the active bar font.
* **Bundled runtime** — Includes the `wayvibes` executable and bundled soundpacks, so a separate `wayvibes` installation is not required.

## Requirements

* **Omarchy 4 (Quattro)**
* A working Quickshell-based Omarchy shell
* Keyboard input access for `wayvibes`

### Keyboard Input Access

Depending on your system configuration, `wayvibes` may require your user to be part of the `input` group:

```bash
sudo usermod -aG input $USER
```

Log out and back in after changing the group.

## Installation

### From the Omarchy Plugin Marketplace

Once OmaVibes is published:

```bash
omarchy plugin add mshareef-git.omavibes --enable
```

### From GitHub

Clone the repository into the Omarchy plugin directory:

```bash
git clone https://github.com/mshareef-git/omavibes.git \
  ~/.config/omarchy/plugins/omavibes
```

Validate the plugin:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/omavibes
```

Enable the plugin on the right side of the bar:

```bash
omarchy plugin enable mshareef-git.omavibes right
```

Restart the shell if necessary:

```bash
omarchy restart shell
```

## Usage

Click the OmaVibes keyboard icon in the Omarchy top bar.

### Search

Use the search field to filter the available soundpacks by name.

### Play a Soundpack

Click any soundpack in the list to start playing it.

The currently selected soundpack is highlighted and marked with a check.

### Random

Click **Random** to choose a random soundpack.

When a search is active, random playback uses the currently filtered soundpacks.

### Turn Off

Click **Turn Off** to stop the currently playing keyboard sounds.

### Volume

Use the volume slider to adjust the current soundpack's volume from 1 to 10.

Each soundpack can have its own saved volume level.

## Soundpacks

OmaVibes includes 25 bundled keyboard soundpacks inside the `packs/` directory.

The soundpacks are included with the plugin so OmaVibes works immediately after installation without requiring users to download additional soundpacks.

### Custom Soundpacks

OmaVibes also supports user soundpacks through:

```text
~/wayvibes/<pack-name>/
```

A custom soundpack can contain the audio files required by `wayvibes` together with its `config.json`.

When a matching user soundpack exists, OmaVibes can use the user version instead of the bundled version.

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
                  +-- Search and filtering
                  +-- Random playback
                  +-- Volume control
                  +-- Persistent settings
                  +-- wayvibes process control
```

The bundled `wayvibes` executable is located at:

```text
bin/wayvibes
```

The bundled soundpacks are located at:

```text
packs/
```

OmaVibes stores its persistent state at:

```text
~/.local/state/omarchy/omavibes.json
```

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
└── packs/
    └── <soundpacks>/
```

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

After making changes, restart the Omarchy shell:

```bash
omarchy restart shell
```

### Before Publishing

Test the following:

* Bar icon appears correctly
* Panel opens and closes correctly
* Soundpack selection works
* Search filtering works
* Random playback works
* Turn Off works
* Volume control works
* Per-pack volume is preserved
* Shell restart does not break the plugin
* Plugin can be disabled and enabled again
* Plugin can be removed cleanly

## Removal

Disable the plugin:

```bash
omarchy plugin disable mshareef-git.omavibes
```

Remove the plugin:

```bash
omarchy plugin remove mshareef-git.omavibes
```

Removing the plugin does not remove user data stored outside the plugin directory, such as:

```text
~/.local/state/omarchy/omavibes.json
~/wayvibes/
```

These can be removed separately if no longer needed.

## Credits

Built for Omarchy Quattro.

Omarchy: [https://omarchy.org/](https://omarchy.org/)

## License

OmaVibes is licensed under the MIT License.

See `LICENSE` for the complete license text.
