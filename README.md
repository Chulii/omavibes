# OmaVibes: Type with Cozy Sound

Cozy typing sounds with 40+ sound effects, detailed analytics, search, random playback, and volume control for the Omarchy bar.

---


https://github.com/user-attachments/assets/370bdda0-ed49-44df-8289-ef5ec577c054


<img width="1536" height="1024" alt="ChatGPT Image Aug 22, 2026, 08_38_00 PM" src="https://github.com/user-attachments/assets/c54c5be6-f218-4c79-9dd3-cc74d1c181ae" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6cccbcc9-a8b1-42de-ac90-bb66c3775293" />
<img width="1916" height="1080" alt="image" src="https://github.com/user-attachments/assets/d857f613-87af-4324-99d8-54e70955ac23" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/89778010-d148-479c-9645-53f73f478dd2" />





`Note: Enable sound in the above preview video`

---

> I didn't originally plan on releasing this.
>
> I created OmaVibes because I wanted those cozy typing sounds while working, but I couldn't afford a dedicated sound setup. So I decided to build my own solution.
>
> OmaVibes originally started with a Walker-based implementation, and eventually evolved into an Omarchy plugin with a proper bar interface, soundpack browser, search, random playback, per-pack volume control, persistent settings, and local typing analytics.
>
> Hopefully you enjoy it.

## What is OmaVibes?

OmaVibes is an Omarchy bar widget that lets you play cozy typing sounds while you type.

It includes 40+ bundled sound effects, a searchable soundpack browser, random playback, volume control, and local typing analytics.


---

## Features

* **Omarchy bar integration** — Open OmaVibes directly from the top bar.
* **40+ sound effects** — A collection of bundled typing sound effects and soundpacks.
* **Soundpack browser** — Browse the available sounds from one panel.
* **Search** — Filter soundpacks instantly by name.
* **One-click playback** — Select a soundpack to start playing it immediately.
* **Random playback** — Pick a random soundpack from the available collection.
* **Turn Off** — Stop the currently playing typing sounds.
* **Volume control** — Adjust the volume from 1 to 10.
* **Per-pack volume** — Each soundpack remembers its own volume setting.
* **Persistent settings** — Soundpack and volume settings are preserved across shell restarts.
* **Typing analytics** — Track words typed, typing time, tracked time, and typing activity.
* **Daily / weekly / monthly views** — View typing activity across real calendar periods.
* **Typing charts** — Visualize word counts, typing time, and typing activity.
* **Typing vs idle** — See how tracked time is divided between active typing and idle time.
* **Typing heatmap** — See which days were more active throughout the month.
* **Consistency statistics** — View active days, streaks, daily averages, and best days.
* **Theme-aware interface** — Uses the active Omarchy theme for the interface and visualizations.
* **Bundled runtime** — Includes the required `wayvibes` executable, so no separate runtime installation is required.

---

## Requirements

* **Omarchy 4 (Quattro)**
* A working Quickshell-based Omarchy shell
* Keyboard input access for `wayvibes`

### Keyboard Input Access

If u are not hearing the sounds depending on your system configuration, `wayvibes` may require your user to have access to Linux keyboard input devices.

If your system does not already provide access, you may need to add your user to the `input` group:

```bash
sudo usermod -aG input $USER
```

restart or log out and back in after changing the group.

---

## Installation

### From the Omarchy Plugin Marketplace

Once OmaVibes is published:

```bash
omarchy plugin add mshareef-git.omavibes --enable
```

### From GitHub

Clone the repository into the Omarchy plugin directory:

```bash
git clone https://github.com/mshareef-git/omavibes.git   ~/.config/omarchy/plugins/omavibes
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

---

## Usage

Click the OmaVibes keyboard icon in the Omarchy top bar.

### Search

When OmaVibes opens, the search field is ready for input.

Type a soundpack name to filter the available sounds.

### Play a Soundpack

Click any soundpack in the list to start playing it.

The currently selected soundpack is highlighted and marked with a check.

### Random

Click **Random** to choose a random soundpack.

When a search is active, random playback uses the currently filtered soundpacks.

### Turn Off

Click **Turn Off** to stop the currently playing typing sounds.

### Volume

Use the volume slider to adjust the current soundpack's volume from 1 to 10.

Each soundpack can have its own saved volume level.

---

## Typing Analytics

OmaVibes includes a local typing analytics panel.

Analytics are optional and only work while the OmaVibes plugin is enabled.

You can choose between two tracking modes:

* **Only when sound effects are enabled** — Track typing while a soundpack is playing.
* **Whenever OmaVibes is enabled** — Track typing whenever the plugin is enabled, even when sounds are not playing.

Analytics include:

* Words typed
* Typing time
* Tracked time
* Typing vs idle time
* Daily, weekly, and monthly charts
* Typing activity graphs
* Monthly typing heatmap
* Consistency statistics
* Daily averages
* Longest typing streaks
* Best typing days

Analytics are stored locally on the user's machine.

OmaVibes stores aggregate typing statistics rather than the actual text typed.

Analytics are stored at:

```text
~/.local/state/omarchy/omavibes-analytics.json
```

Normal OmaVibes settings are stored separately at:

```text
~/.local/state/omarchy/omavibes.json
```

---

## Soundpacks

OmaVibes includes 40+ bundled sound effects inside the `packs/` directory.

The soundpacks are included with the plugin so OmaVibes works immediately after installation without requiring users to download additional sound files.

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
    |     |
    |     +-- Soundpack browser
    |     +-- Search
    |     +-- Random playback
    |     +-- Volume control
    |     +-- Analytics interface
    |
    +-- OmaVibesState.qml
          |
          +-- Soundpack selection
          +-- Search and filtering
          +-- Random playback
          +-- Volume control
          +-- Persistent settings
          +-- Analytics state
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

Persistent sound settings are stored at:

```text
~/.local/state/omarchy/omavibes.json
```

Typing analytics are stored separately at:

```text
~/.local/state/omarchy/omavibes-analytics.json
```

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
        ├── src/
        ├── Makefile
        └── build.sh
```

---

## Development

From the plugin directory, validate the plugin with:

```bash
omarchy plugin validate .
```

Run QML linting against the Omarchy shell:

```bash
qmllint -I "$OMARCHY_PATH/shell"   BarWidget.qml   Panel.qml   OmaVibesState.qml
```

After making changes, restart the Omarchy shell:

```bash
omarchy restart shell
```

### Wayvibes

The `wayvibes` runtime is maintained as part of the plugin under:

```text
third_party/wayvibes/
```

The runtime can be rebuilt with:

```bash
cd third_party/wayvibes
./build.sh
```

A GitHub Actions workflow is used to build the Wayvibes binary and generate build provenance for it.

---

## Before Publishing

Test the following:

* Bar icon appears correctly
* Panel opens and closes correctly
* Search field receives focus when the panel opens
* Soundpack selection works
* Search filtering works
* Random playback works
* Turn Off works
* Volume control works
* Per-pack volume is preserved
* Shell restart does not break the plugin
* Analytics tracking modes work
* Daily, weekly, and monthly analytics display correctly
* Typing heatmap displays correctly
* Hover information works where available
* Consistency statistics display correctly
* Plugin can be disabled and enabled again
* Plugin can be removed cleanly

---

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
~/.local/state/omarchy/omavibes-analytics.json
~/wayvibes/
```

These can be removed separately if no longer needed.

---

## Credits

Built for Omarchy Quattro.

Omarchy: https://omarchy.org/

## License

OmaVibes is licensed under the MIT License.

See `LICENSE` for the complete license text.
