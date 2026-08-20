import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

Panel {
    id: root

    moduleName: "io.github.mshareef-git.omavibes"
    manageIpc: false

    property var anchorItem: null
    property var hostWidget: null
    property var omaState: OmaVibesState

    property string searchText: ""
    property int highlightedIndex: -1

    readonly property string uiFont:
        root.bar ? root.bar.fontFamily : Style.font.family

    readonly property var filteredPacks:
        omaState && omaState.packs
            ? omaState.packs.filter(
                p => p.name.toLowerCase().includes(searchText.toLowerCase())
              )
            : []

    function formatPackName(name) {
        if (!name)
            return ""

        var special = {
            "nl": "NL",
            "osu": "OSU",
            "nk": "NK",
            "eg": "EG",
            "pbt": "PBT",
            "abs": "ABS",
            "mx": "MX",
            "8": "8"
        }

        return name.split(" ").map(function(word) {
            var lower = word.toLowerCase()

            if (special[lower])
                return special[lower]

            if (lower === "cherrymx")
                return "CherryMX"

            if (!word.length)
                return word

            return word.charAt(0).toUpperCase() + word.slice(1)
        }).join(" ")
    }

    function open() {
        root.controller.show()
    }

    function close() {
        root.searchText = ""
        root.highlightedIndex = -1
        root.controller.hide()
    }

    function toggle() {
        if (root.opened)
            root.close()
        else
            root.open()
    }

    function setVolumeFromPosition(mouseX, width) {
        if (!omaState.currentPack || width <= 0)
            return

        var ratio = Math.max(0, Math.min(1, mouseX / width))
        var value = 1 + Math.round(ratio * 9)

        omaState.setVolume(value)
    }

    function resetHighlight() {
        Qt.callLater(function() {
            highlightedIndex = filteredPacks.length > 0 ? 0 : -1

            if (highlightedIndex >= 0)
                packList.positionViewAtIndex(
                    highlightedIndex,
                    ListView.Beginning
                )
        })
    }

    function moveHighlight(direction) {
        if (filteredPacks.length === 0) {
            highlightedIndex = -1
            return
        }

        var nextIndex = highlightedIndex + direction

        if (nextIndex < 0)
            nextIndex = 0

        if (nextIndex >= filteredPacks.length)
            nextIndex = filteredPacks.length - 1

        highlightedIndex = nextIndex

        packList.positionViewAtIndex(
            highlightedIndex,
            ListView.Contain
        )
    }

    function playHighlighted() {
        if (
            highlightedIndex >= 0 &&
            highlightedIndex < filteredPacks.length
        ) {
            omaState.play(
                filteredPacks[highlightedIndex].name
            )
        }
    }

    KeyboardPanel {
        id: panel

        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened

        PanelKeyCatcher {
            id: keyCatcher

            anchors.fill: parent

            onCloseRequested: root.close()

            Column {
                id: content

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                anchors.margins: Style.space(2)

                spacing: Style.space(10)

                // ─────────────────────────
                // HEADER
                // ─────────────────────────

                Text {
                    width: parent.width

                    text: "⌨ OmaVibes"

                    color: Color.popups.text

                    font.family: root.uiFont
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text:
                        omaState.isPlaying && omaState.currentPack
                            ? "Now playing: " +
                              root.formatPackName(omaState.currentPack)
                            : "Now playing: None"

                    color: Color.muted

                    font.family: root.uiFont
                    font.pixelSize: 13

                    elide: Text.ElideRight
                }

                // ─────────────────────────
                // SEARCH
                // ─────────────────────────

                TextField {
                    id: searchField

                    width: parent.width
                    height: 44

                    placeholderText: "Search soundpacks..."
                    text: root.searchText

                    font.family: root.uiFont
                    font.pixelSize: 14

                    onTextChanged: {
                        if (root.searchText !== text)
                            root.searchText = text

                        root.resetHighlight()
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            root.moveHighlight(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.moveHighlight(-1)
                            event.accepted = true
                        } else if (
                            event.key === Qt.Key_Return ||
                            event.key === Qt.Key_Enter
                        ) {
                            root.playHighlighted()
                            event.accepted = true
                        }
                    }
                }

                // ─────────────────────────
                // SOUND LIST + ACTIONS
                // ─────────────────────────

                Row {
                    id: mainArea

                    width: parent.width
                    height: 235

                    spacing: Style.space(10)

                    // SOUND LIST
                    Rectangle {
                        width: parent.width * 0.68
                        height: parent.height

                        color: Color.popups.background
                        radius: Style.cornerRadius

                        border.width: 1
                        border.color: Color.popups.border

                        ListView {
                            id: packList

                            anchors.fill: parent
                            anchors.margins: 5

                            clip: true
                            spacing: 2

                            model: root.filteredPacks

                            delegate: Rectangle {
                                width: packList.width
                                height: 38

                                radius: 8

                                property bool selected:
                                    omaState.currentPack === modelData.name

                                property bool keyboardSelected:
                                    index === root.highlightedIndex

                                color:
                                    keyboardSelected
                                        ? Style.selectedFillFor(
                                            Color.popups.text,
                                            Color.accent
                                          )
                                        : selected
                                            ? Style.selectedFillFor(
                                                Color.popups.text,
                                                Color.accent
                                              )
                                            : mouseArea.containsMouse
                                                ? Style.hoverFillFor(
                                                    Color.popups.text,
                                                    Color.accent
                                                  )
                                                : "transparent"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12

                                    anchors.right: check.left
                                    anchors.rightMargin: 8

                                    anchors.verticalCenter: parent.verticalCenter

                                    text: root.formatPackName(modelData.name)

                                    color: Color.popups.text

                                    font.family: root.uiFont
                                    font.pixelSize: 14

                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: check

                                    anchors.right: parent.right
                                    anchors.rightMargin: 12

                                    anchors.verticalCenter: parent.verticalCenter

                                    text: "✓"

                                    visible: parent.selected

                                    color: Color.accent

                                    font.family: root.uiFont
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                MouseArea {
                                    id: mouseArea

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    onClicked: {
                                        root.highlightedIndex = index
                                        omaState.play(modelData.name)
                                    }
                                }
                            }
                        }
                    }

                    // ACTION BUTTONS
                    Column {
                        width: parent.width * 0.32 - parent.spacing
                        height: parent.height

                        spacing: Style.space(10)

                        Rectangle {
                            width: parent.width
                            height: (parent.height - parent.spacing) / 2

                            radius: 10

                            color:
                                randomMouse.containsMouse
                                    ? Style.hoverFillFor(
                                        Color.popups.text,
                                        Color.accent
                                      )
                                    : Color.popups.background

                            border.width: 1
                            border.color: Color.popups.border

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "\uedec"
                                    color:Color.accent

                                    font.pixelSize: 20
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Random"

                                    color: Color.popups.text

                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: randomMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    if (root.filteredPacks.length > 0) {
                                        var randomIndex =
                                            Math.floor(
                                                Math.random() *
                                                root.filteredPacks.length
                                            )

                                        omaState.play(
                                            root.filteredPacks[randomIndex].name
                                        )
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: (parent.height - parent.spacing) / 2

                            radius: 10

                            color:
                                stopMouse.containsMouse
                                    ? Style.hoverFillFor(
                                        Color.popups.text,
                                        Color.accent
                                      )
                                    : Color.popups.background

                            border.width: 1
                            border.color: Color.popups.border

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "\udb81\udd81"
                                    color:Color.accent

                                    font.pixelSize: 20
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Turn Off"

                                    color: Color.popups.text

                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: stopMouse

                                anchors.fill: parent

                                hoverEnabled: true

                                onClicked: {
                                    omaState.stop()
                                }
                            }
                        }
                    }
                }

                // ─────────────────────────
                // VOLUME HEADER
                // ─────────────────────────

                Text {
                    text:
                        omaState.currentPack
                            ? "Volume: " +
                              Math.round(
                                  omaState.volumeFor(
                                      omaState.currentPack
                                  )
                              )
                            : "Volume: —"

                    color: Color.popups.text

                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.bold: true
                }

                // ─────────────────────────
                // VOLUME SLIDER
                // ─────────────────────────

                Rectangle {
                    id: volumeTrack

                    width: parent.width
                    height: 24

                    color: "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: 5
                        radius: 3

                        color: Color.popups.border
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        width:
                            omaState.currentPack
                                ? volumeTrack.width *
                                  (
                                      (
                                          omaState.volumeFor(
                                              omaState.currentPack
                                          ) - 1
                                      ) / 9
                                  )
                                : 0

                        height: 5
                        radius: 3

                        color: Color.accent
                    }

                    Rectangle {
                        width: 16
                        height: 16

                        radius: 8

                        x:
                            omaState.currentPack
                                ? (
                                    volumeTrack.width - width
                                  ) *
                                  (
                                      (
                                          omaState.volumeFor(
                                              omaState.currentPack
                                          ) - 1
                                      ) / 9
                                  )
                                : 0

                        anchors.verticalCenter: parent.verticalCenter

                        color: Color.accent

                        border.width: 2
                        border.color: Color.popups.background
                    }

                    MouseArea {
                        anchors.fill: parent

                        enabled: omaState.currentPack !== ""

                        onPressed: function(mouse) {
                            root.setVolumeFromPosition(
                                mouse.x,
                                volumeTrack.width
                            )
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                root.setVolumeFromPosition(
                                    mouse.x,
                                    volumeTrack.width
                                )
                            }
                        }
                    }
                }
            }
        }

        contentWidth: panel.fittedContentWidth(
            Style.space(400)
        )

        contentHeight: panel.fittedContentHeight(
            content.implicitHeight +
            Style.space(18)
        )
    }
}
