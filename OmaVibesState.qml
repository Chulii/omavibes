pragma Singleton
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: state

    readonly property string pluginDir: decodeURIComponent(
        Qt.resolvedUrl("./").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    )
    readonly property string pluginBin: pluginDir + "/bin/wayvibes"
    readonly property string pluginPacksDir: pluginDir + "/packs/"
    readonly property string userPacksDir: Quickshell.env("HOME") + "/wayvibes/"
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/omarchy/omavibes.json"

    readonly property var packs: [
        { name: "8 bit",                             folder: "8 bit" },
        { name: "akko lavender purples",              folder: "akko_lavender_purples" },
        { name: "animal crossing nl",                 folder: "animal_crossing_nl" },
        { name: "banana split lubed",                 folder: "banana split lubed" },
        { name: "boxjade",                            folder: "boxjade" },
        { name: "Chalks",                             folder: "chalks" },
        { name: "cherrymx black abs",                 folder: "cherrymx-black-abs" },
        { name: "cherrymx black pbt",                 folder: "cherrymx-black-pbt" },
        { name: "cherrymx blue abs",                  folder: "cherrymx-blue-abs" },
        { name: "cherrymx blue pbt",                  folder: "cherrymx-blue-pbt" },
        { name: "cherrymx brown pbt",                 folder: "cherrymx-brown-pbt" },
        { name: "cherrymx red abs",                   folder: "cherrymx-red-abs" },
        { name: "cherrymx red pbt",                   folder: "cherrymx-red-pbt" },
        { name: "Dino Alpacas",                       folder: "Dino_Alpacas" },
        { name: "eg oreo",                            folder: "eg-oreo" },
        { name: "Farts",                              folder: "Farts" },
        { name: "Koala",                              folder: "Koala" },
        { name: "Lincoln Typewriter",                 folder: "Lincoln Typewriter" },
        { name: "nk cream",                           folder: "nk-cream" },
        { name: "osu",                                folder: "osu" },
        { name: "penumbra",                           folder: "penumbra" },
        { name: "Press",                              folder: "Press" },
        { name: "Razer Green (Blackwidow Elite)",     folder: "Razer Green (Blackwidow Elite) - Akira" },
        { name: "shadowgun",                          folder: "shadowgun" },
        { name: "sine bumps 2",                       folder: "sine bumps 2" },
        { name: "tealios v2 Akira",                   folder: "tealios-v2_Akira" },
        { name: "Thocks",                             folder: "Thocks" },
        { name: "trails in the sky",                  folder: "trails-in-the-sky" },
        { name: "Trust GXT 865 ASTA",                 folder: "Trust_GXT_865_ASTA" }
    ]

    property string currentPack: ""
    property bool isPlaying: false
    property var packVolumes: ({})
    readonly property int defaultVolume: 3

    function volumeFor(packName) {
        return packVolumes[packName] !== undefined ? packVolumes[packName] : defaultVolume
      }
      
    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function play(packName) {
        const pack = packs.find(p => p.name === packName)
        if (!pack) return

        stopProc.running = true
        stopProc.exited.connect(function onExit() {
            stopProc.exited.disconnect(onExit)
            startTimer.packFolder = pack.folder
            startTimer.packName = pack.name
            startTimer.start()
        })
    }

    function stop() {
        stopProc.running = true
        state.currentPack = ""
        state.isPlaying = false
        save()
    }

    function setVolume(vol) {
        if (!currentPack) return
        packVolumes[currentPack] = vol
        packVolumesChanged()
        save()
        play(currentPack)
    }

    function randomPack() {
        if (packs.length === 0) return
        const p = packs[Math.floor(Math.random() * packs.length)]
        play(p.name)
    }

    property Process stopProc: Process {
        command: ["pkill", "-x", "wayvibes"]
    }

    property Timer startTimer: Timer {
        id: startTimer
        interval: 300
        property string packFolder: ""
        property string packName: ""
    onTriggered: {
        const volumeValue = Number(state.volumeFor(packName))
        const volume = Number.isFinite(volumeValue)
            ? Math.max(1, Math.min(10, Math.round(volumeValue)))
            : state.defaultVolume

        const pluginBin = shellQuote(state.pluginBin)
        const pluginPackDir = shellQuote(
            state.pluginPacksDir + packFolder
        )
        const userPackDir = shellQuote(
            state.userPacksDir + packFolder
        )

        const launchCmd =
            "BIN=$(which wayvibes 2>/dev/null || echo " + pluginBin + "); " +
            "PACK_DIR=" + pluginPackDir + "; " +
            "[ -d " + userPackDir + " ] && PACK_DIR=" + userPackDir + "; " +
            "$BIN \"$PACK_DIR/\" -v " + String(volume) + " -bg"

        launchProc.command = ["bash", "-c", launchCmd]
        launchProc.running = true

        state.currentPack = packName
        state.isPlaying = true
        state.save()
    }
    }

    property Process launchProc: Process {}

    function load() {
        readProc.running = true
    }

    function save() {
        const payload = JSON.stringify({
            currentPack: currentPack,
            packVolumes: packVolumes
        })
        const safePayload = payload.replace(/'/g, "'\\''")
        writeProc.command = [
            "bash", "-c",
            "mkdir -p ~/.local/state/omarchy && printf '%s' '" + safePayload + "' > '" + stateFile + "'"
        ]
        writeProc.running = true
    }

    property Process writeProc: Process {}

    property Process readProc: Process {
        id: readProc
        command: ["bash", "-c", "cat '" + state.stateFile + "' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data.currentPack) state.currentPack = data.currentPack
                    if (data.packVolumes) state.packVolumes = data.packVolumes
                    state.isPlaying = false
                } catch (e) {
                }
            }
        }
    }

    Component.onCompleted: load()
}
