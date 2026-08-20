# OmaVibes
<img width="1536" height="1024" alt="preview" src="https://github.com/user-attachments/assets/ce817e0f-87d0-48ce-8689-35115b2382ec" />
<img width="1899" height="1080" alt="preview1" src="https://github.com/user-attachments/assets/288f805b-8436-4ba8-bb2f-b9d572ca87c1" />


https://github.com/user-attachments/assets/c6a59ad7-b5af-4149-bff5-a7361f42ecd2



I did'nt actually planned on releasing this for some reason i changed my mind and the reason i created this plugin is because i couldn't afford the mechanical keyboard sounds those thocky,creamy ones. so what i did is create a plugin (originally it was using walker) that plays mechanical keyboard sounds while using the keyboard. it has different types of sounds which i mentioned below. hope u enjoy this. heres the detail about the plugin
OmaVibes lets you browse, search, select, randomize, and control the volume of keyboard soundpacks directly from the Omarchy top bar.

Features

- Omarchy bar integration — Open OmaVibes directly from the top bar.
- Soundpack browser — Browse bundled mechanical keyboard soundpacks.
- Search — Filter soundpacks instantly by name.
- One-click playback — Select a soundpack to start it immediately.
- Random playback — Pick a random soundpack from the visible collection.
- Turn Off — Stop the currently playing keyboard sounds.
- Per-pack volume — Store a separate volume level for each soundpack.
- Persistent settings — Remember the current soundpack and volume settings across shell restarts.
- Theme-aware UI — Uses Omarchy/Quickshell styling and the active bar font.
- Bundled runtime — Includes the "wayvibes" executable and bundled soundpacks, so a separate "wayvibes" installation is not required.

Requirements

- Omarchy 4 (Quattro) or a compatible Quickshell-based Omarchy shell.
- Keyboard input access for the "wayvibes" runtime.

On systems where keyboard input access is not already configured, "wayvibes" may require your user to be in the "input" group:

sudo usermod -aG input $USER

Log out and back in after changing the group.

Installation

From the Omarchy Plugin Marketplace

Once OmaVibes is published:

omarchy plugin add io.github.YOUR_GITHUB_USERNAME.omavibes --enable

From GitHub

Clone the repository into the Omarchy plugin directory:

git clone <https://github.com/YOUR_GITHUB_USERNAME/omavibes.git> \
  ~/.config/omarchy/plugins/omavibes

Validate the plugin:

omarchy plugin validate ~/.config/omarchy/plugins/omavibes

Enable it on the right side of the bar:

omarchy plugin enable io.github.YOUR_GITHUB_USERNAME.omavibes right

Usage

Click the OmaVibes keyboard icon in the Omarchy top bar.

The panel provides:

- Search — Filter the available soundpacks.
- Soundpack list — Click a pack to start it.
- Random — Choose a random soundpack.
- Turn Off — Stop the current keyboard sounds.
- Volume — Adjust the volume from 1 to 10.
- Selected indicator — The currently selected pack is highlighted and marked with a check.

Soundpacks

OmaVibes includes a collection of keyboard soundpacks inside the "packs/" directory.

The bundled packs are included so OmaVibes works immediately after installation without requiring users to download additional soundpacks.

Custom Soundpacks

OmaVibes also supports user soundpacks through:

~/wayvibes/<pack-name>/

A custom soundpack can contain the audio files required by "wayvibes" together with its "config.json".

When a matching user pack exists, OmaVibes can use the user version instead of the bundled version.

How It Works

OmaVibes is implemented as a Quickshell/Omarchy "bar-widget".

BarWidget.qml
    │
    └── Panel.qml
          │
          └── OmaVibesState.qml
                  │
                  ├── Soundpack selection
                  ├── Search/filter state
                  ├── Volume control
                  ├── Persistent settings
                  └── wayvibes process control

The bundled "wayvibes" executable is located at:

bin/wayvibes

Bundled soundpacks are located at:

packs/

OmaVibes stores its persistent state at:

~/.local/state/omarchy/omavibes.json

Repository Structure

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

Development

Validate the plugin before publishing:

omarchy plugin validate .

Run QML linting against the installed Omarchy shell:

qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml \
  Panel.qml \
  OmaVibesState.qml

After making changes, restart the Omarchy shell when necessary:

omarchy restart shell

Before publishing, test:

- Opening the bar widget
- Closing it with Escape
- Soundpack selection
- Search
- Random playback
- Turn Off
- Volume control
- Shell restart
- Disable/re-enable
- Plugin removal

Safe Removal

Disable the plugin:

omarchy plugin disable io.github.YOUR_GITHUB_USERNAME.omavibes

Remove the plugin:

omarchy plugin remove io.github.YOUR_GITHUB_USERNAME.omavibes

Removing the plugin does not remove user data stored outside the plugin directory, such as:

~/.local/state/omarchy/omavibes.json
~/wayvibes/

Credits

OmaVibes is built for Omarchy Quattro and uses the wayvibes keyboard sound runtime.

- Omarchy — <https://omarchy.org/>
- wayvibes — <https://github.com/sahaj-b/wayvibes>

License

OmaVibes is licensed under the MIT License.

See "LICENSE" (LICENSE) for the complete license text.
