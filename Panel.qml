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
    property string activeView: "sounds" // "sounds" | "analytics"
    property string analyticsGraphView: "day" // "day" | "week" | "month"

    function analyticsWordsTooltip(item) {
        if (!item) return ""
        const words = Number(item.value || 0).toLocaleString()
        if (item.dateKey) {
            const parts = String(item.dateKey).split("-")
            if (parts.length === 3)
                return String(item.label) + " " + Number(parts[2]) + "  •  " + words + " words"
        }
        return String(item.label) + "  •  " + words + " words"
    }

    readonly property string uiFont:
        root.bar ? root.bar.fontFamily : Style.font.family

    // Visualization-only theme roles. Normal OmaVibes UI keeps its existing palette.
    readonly property color vizPrimary: Color.accent
    readonly property color vizSecondary: Color.urgent
    readonly property color vizNeutral: Color.popups.text
    readonly property color vizMuted: Color.muted

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
        root.activeView = "sounds"
        root.controller.show()
        Qt.callLater(function() {
            if (searchField)
                searchField.forceActiveFocus()
        })
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
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(400))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

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
                    visible: root.activeView === "sounds"

                    text: omaState.todayRemarkText()

                    color: root.vizPrimary
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.bold: true

                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // ─────────────────────────
                // SEARCH
                // ─────────────────────────

                TextField {
                    id: searchField

                    width: parent.width
                    height: 44
                    visible: root.activeView === "sounds"

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
                    visible: root.activeView === "sounds"

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
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }


                            delegate: Rectangle {
                                width: packList.width
                                height: 38

                                radius: 8

                                property bool selected:
                                    omaState.currentPack === modelData.name

                                property bool keyboardSelected:
                                    index === root.highlightedIndex

                                // subtle alternating row shading so eyes
                                // track rows while scanning a long list
                                readonly property color zebraColor: Qt.rgba(
                                    Color.popups.text.r,
                                    Color.popups.text.g,
                                    Color.popups.text.b,
                                    0.035
                                )

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
                                                : (index % 2 === 0 ? zebraColor : "transparent")

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
                            height: (parent.height - 2 * parent.spacing) / 3

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
                            height: (parent.height - 2 * parent.spacing) / 3

                            radius: 10

                            color:
                                analyticsMouse.containsMouse
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

                                    // ⚠️ VERIFY: bar-chart glyph codepoint —
                                    // swap for whatever your bundled Nerd
                                    // Font actually maps if this renders
                                    // as a blank box.
                                    text: "\uf080"
                                    color: Color.accent

                                    font.pixelSize: 20
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    text: "Analytics"

                                    color: Color.popups.text

                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                id: analyticsMouse

                                anchors.fill: parent

                                hoverEnabled: true

onClicked: {
    root.activeView = "analytics"
}
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: (parent.height - 2 * parent.spacing) / 3

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
                    visible: root.activeView === "sounds"

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
                    visible: root.activeView === "sounds"

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

                Text {
                    width: parent.width
                    visible: root.activeView === "sounds"

                    text:
                        omaState.isPlaying && omaState.currentPack
                            ? "Now playing: " +
                              root.formatPackName(omaState.currentPack)
                            : "Now playing: None"

                    color: Color.muted
                    font.family: root.uiFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                // ─────────────────────────
                // ANALYTICS
                // ─────────────────────────

                Column {
                    id: analyticsView

                    width: parent.width
                    visible: root.activeView === "analytics"
                    spacing: Style.space(10)

                    Row {
                        width: parent.width
                        spacing: Style.space(6)

                        Text {
                            text: "←"
                            color: Color.accent
                            font.family: root.uiFont
                            font.pixelSize: 16
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                onClicked: root.activeView = "sounds"
                            }
                        }

                        Text {
                            text: "Back to Sounds"
                            color: Color.muted
                            font.family: root.uiFont
                            font.pixelSize: 13

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: root.activeView = "sounds"
                            }
                        }
                    }

                    Flickable {
                        id: analyticsFlick

                        width: parent.width
                        height: 520
                        clip: true

                        contentWidth: width
                        contentHeight: analyticsContent.implicitHeight

                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Column {
                            id: analyticsContent

                            width: analyticsFlick.width
                            spacing: Style.space(10)

                            // ── PERIOD NAVIGATION ──
                            Row {
                                width: parent.width
                                height: 28

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: "‹"
                                    color: Color.accent
                                    font.family: root.uiFont
                                    font.pixelSize: 20
                                    font.bold: true

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        onClicked: omaState.moveAnalyticsPeriod(-1, root.analyticsGraphView)
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent

                                    text: omaState.analyticsPeriodLabel(
                                        root.analyticsGraphView
                                    )

                                    color: Color.popups.text
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter

                                    text: "›"
                                    color: Color.accent
                                    font.family: root.uiFont
                                    font.pixelSize: 20
                                    font.bold: true

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -5
                                        onClicked: omaState.moveAnalyticsPeriod(1, root.analyticsGraphView)
                                    }
                                }
                            }

                            // ── RANGE TABS ──
                            Row {
                                spacing: Style.space(14)

                                Repeater {
                                    model: ["Day", "Week", "Month"]

                                    delegate: Text {
                                        text: modelData
                                        color:
                                            root.analyticsGraphView === modelData.toLowerCase()
                                                ? Color.accent
                                                : Color.muted

                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                        font.bold:
                                            root.analyticsGraphView === modelData.toLowerCase()

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -5
                                            onClicked: {
                                                root.analyticsGraphView = modelData.toLowerCase()
                                            }
                                        }
                                    }
                                }
                            }

                            // ── TODAY SUMMARY ──
                            Column {
                                width: parent.width
                                spacing: 1

                                Text {
                                    text: "TODAY"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    text: omaState.todayWords().toLocaleString() + " words"
                                    color: Color.popups.text
                                    font.family: root.uiFont
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                Text {
                                    readonly property real pct: omaState.wordsChangePercent()
                                    text:
                                        omaState.yesterdayWords() === 0
                                            ? "No previous-day comparison"
                                            : ((pct >= 0 ? "+" : "") +
                                               pct.toFixed(1) +
                                               "% from yesterday")

                                    color:
                                        omaState.yesterdayWords() === 0
                                            ? Color.muted
                                            : (pct >= 0 ? Color.accent : Color.muted)

                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── WORDS BAR CHART ──
                            Column {
                                width: parent.width
                                spacing: Style.space(6)

                                Text {
                                    text: "WORDS TYPED"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    id: wordsChart

                                    width: parent.width
                                    height: 150

                                    readonly property var series:
                                        omaState.analyticsWordsSeries(root.analyticsGraphView)

                                    readonly property real maxValue:
                                        wordsChart.series.reduce(
                                            function(maximum, item) {
                                                return Math.max(maximum, Number(item.value) || 0)
                                            },
                                            1
                                        )

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: Color.popups.border
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.bottomMargin: 10
                                        spacing: Style.space(4)

                                        Repeater {
                                            model: wordsChart.series

                                            delegate: Item {
                                                width:
                                                    (wordsChart.width -
                                                     (wordsChart.series.length - 1) * Style.space(4))
                                                    / wordsChart.series.length
                                                height: wordsChart.height - 10

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter

                                                    width: Math.max(5, parent.width * 0.48)
                                                    height:
                                                        modelData.value > 0
                                                            ? Math.max(
                                                                3,
                                                                (parent.height - 24) *
                                                                (Number(modelData.value) / wordsChart.maxValue)
                                                              )
                                                            : 2

                                                    radius: 3
                                                    color:
                                                        modelData.isToday
                                                            ? root.vizSecondary
                                                            : (Number(modelData.value) > 0
                                                                ? root.vizPrimary
                                                                : Color.popups.border)
                                                }

                                                Text {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter

                                                    text: modelData.label
                                                    color:
                                                        modelData.isToday
                                                            ? Color.popups.text
                                                            : Color.muted

                                                    font.family: root.uiFont
                                                    font.pixelSize: 9
                                                    font.bold: modelData.isToday
                                                }

                                                Text {
                                                    visible: modelData.value > 0
                                                    anchors.bottom: parent.bottom
                                                    anchors.bottomMargin: 22
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter

                                                    text:
                                                        Number(modelData.value).toLocaleString()

                                                    color: root.vizNeutral
                                                    font.family: root.uiFont
                                                    font.pixelSize: 8
                                                    elide: Text.ElideRight
                                                }

                                                MouseArea {
                                                    id: wordsHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                }

                                                Rectangle {
                                                    visible: wordsHover.containsMouse
                                                    z: 20
                                                    width: wordsTooltipText.implicitWidth + 16
                                                    height: 24
                                                    radius: 4
                                                    color: Color.popups.background
                                                    border.width: 1
                                                    border.color: Color.popups.border
                                                    x: Math.max(0, Math.min(parent.width - width, (parent.width - width) / 2))
                                                    y: 0

                                                    Text {
                                                        id: wordsTooltipText
                                                        anchors.centerIn: parent
                                                        text: root.analyticsWordsTooltip(modelData)
                                                        color: Color.popups.text
                                                        font.family: root.uiFont
                                                        font.pixelSize: 9
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: wordsChart.series.every(function(item) {
                                            return Number(item.value) === 0
                                        })

                                        text: "No typing data for this period"
                                        color: Color.muted
                                        font.family: root.uiFont
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── TYPING TREND LINE ──
                            Column {
                                width: parent.width
                                spacing: Style.space(6)

                                Text {
                                    text: "TYPING TIME TREND"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    id: typingLineChart

                                    width: parent.width
                                    height: 135

                                    readonly property var series:
                                        omaState.analyticsTypingSeries(root.analyticsGraphView)

                                    property int hoverIndex: -1

                                    Canvas {
                                        id: typingCanvas

                                        anchors.fill: parent

                                        onPaint: {
                                            const ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)

                                            const left = 6
                                            const right = width - 6
                                            const top = 8
                                            const bottom = height - 22
                                            const chartW = right - left
                                            const chartH = bottom - top

                                            const values = typingLineChart.series.map(
                                                function(item) {
                                                    return Number(item.value) || 0
                                                }
                                            )

                                            let maxValue = values.reduce(
                                                function(maximum, value) {
                                                    return Math.max(maximum, value)
                                                },
                                                1
                                            )

                                            ctx.strokeStyle = String(Color.popups.border)
                                            ctx.lineWidth = 1

                                            for (let i = 0; i < 3; i++) {
                                                const y = top + (chartH * i / 2)
                                                ctx.beginPath()
                                                ctx.moveTo(left, y)
                                                ctx.lineTo(right, y)
                                                ctx.stroke()
                                            }

                                            ctx.strokeStyle = String(root.vizPrimary)
                                            ctx.lineWidth = 2
                                            ctx.beginPath()

                                            for (let i = 0; i < values.length; i++) {
                                                const x =
                                                    values.length === 1
                                                        ? left + chartW / 2
                                                        : left + chartW * i / (values.length - 1)

                                                const y =
                                                    bottom -
                                                    chartH * (values[i] / maxValue)

                                                if (i === 0)
                                                    ctx.moveTo(x, y)
                                                else
                                                    ctx.lineTo(x, y)
                                            }

                                            ctx.stroke()

                                            ctx.fillStyle = String(root.vizPrimary)

                                            for (let i = 0; i < values.length; i++) {
                                                const x =
                                                    values.length === 1
                                                        ? left + chartW / 2
                                                        : left + chartW * i / (values.length - 1)

                                                const y =
                                                    bottom -
                                                    chartH * (values[i] / maxValue)

                                                ctx.fillStyle = String(
                                                    typingLineChart.series[i].isToday
                                                        ? root.vizSecondary
                                                        : root.vizPrimary
                                                )
                                                ctx.beginPath()
                                                ctx.arc(x, y, 3, 0, Math.PI * 2)
                                                ctx.fill()
                                            }

                                            ctx.fillStyle = String(Color.muted)
                                            ctx.font = "9px " + String(root.uiFont)

                                            for (let i = 0; i < typingLineChart.series.length; i++) {
                                                const x =
                                                    values.length === 1
                                                        ? left + chartW / 2
                                                        : left + chartW * i / (values.length - 1)

                                                ctx.textAlign = "center"
                                                ctx.fillText(
                                                    typingLineChart.series[i].label,
                                                    x,
                                                    height - 5
                                                )
                                            }

                                            if (values.every(function(value) { return value === 0 })) {
                                                ctx.fillStyle = String(Color.muted)
                                                ctx.textAlign = "center"
                                                ctx.fillText(
                                                    "No typing data for this period",
                                                    width / 2,
                                                    height / 2
                                                )
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: typingHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onPositionChanged: function(mouse) {
                                            const count = typingLineChart.series.length
                                            if (count <= 0) {
                                                typingLineChart.hoverIndex = -1
                                                return
                                            }
                                            const left = 6
                                            const right = width - 6
                                            const ratio = Math.max(0, Math.min(1, (mouse.x - left) / Math.max(1, right - left)))
                                            typingLineChart.hoverIndex = Math.max(0, Math.min(count - 1, Math.round(ratio * (count - 1))))
                                        }
                                        onExited: typingLineChart.hoverIndex = -1
                                    }

                                    Rectangle {
                                        visible: typingLineChart.hoverIndex >= 0
                                        z: 25
                                        width: typingTooltipText.implicitWidth + 16
                                        height: 28
                                        radius: 4
                                        color: Color.popups.background
                                        border.width: 1
                                        border.color: Color.popups.border
                                        x: {
                                            if (typingLineChart.hoverIndex < 0) return 0
                                            const count = typingLineChart.series.length
                                            const left = 6
                                            const right = typingLineChart.width - 6
                                            const pointX = count <= 1 ? typingLineChart.width / 2 : left + (right - left) * typingLineChart.hoverIndex / (count - 1)
                                            return Math.max(0, Math.min(typingLineChart.width - width, pointX - width / 2))
                                        }
                                        y: 1

                                        Text {
                                            id: typingTooltipText
                                            anchors.centerIn: parent
                                            text: typingLineChart.hoverIndex < 0
                                                ? ""
                                                : String(typingLineChart.series[typingLineChart.hoverIndex].label) + "  •  " +
                                                  omaState.formatDurationPrecise(typingLineChart.series[typingLineChart.hoverIndex].value)
                                            color: Color.popups.text
                                            font.family: root.uiFont
                                            font.pixelSize: 9
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── TYPING VS IDLE DONUT ──
                            Row {
                                width: parent.width
                                spacing: Style.space(14)

                                Item {
                                    width: 125
                                    height: 125

                                    Canvas {
                                        id: donutCanvas
                                        anchors.fill: parent

                                        onPaint: {
                                            const ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)

                                            const centerX = width / 2
                                            const centerY = height / 2
                                            const radius = 48
                                            const lineWidth = 16

                                            const stats =
                                                omaState.analyticsPeriodStats(
                                                    root.analyticsGraphView
                                                )

                                            const typing = Math.max(0, Number(stats.typingSeconds) || 0)
                                            const idle = Math.max(0, Number(stats.idleSeconds) || 0)
                                            const total = typing + idle

                                            ctx.lineWidth = lineWidth

                                            if (total > 0) {
                                                const typingAngle =
                                                    (typing / total) * Math.PI * 2

                                                const idleAngle =
                                                    (idle / total) * Math.PI * 2

                                                ctx.strokeStyle = String(root.vizSecondary)
                                                ctx.beginPath()
                                                ctx.arc(
                                                    centerX,
                                                    centerY,
                                                    radius,
                                                    -Math.PI / 2 + typingAngle,
                                                    -Math.PI / 2 + typingAngle + idleAngle
                                                )
                                                ctx.stroke()

                                                ctx.strokeStyle = String(root.vizPrimary)
                                                ctx.beginPath()
                                                ctx.arc(
                                                    centerX,
                                                    centerY,
                                                    radius,
                                                    -Math.PI / 2,
                                                    -Math.PI / 2 + typingAngle
                                                )
                                                ctx.stroke()
                                            } else {
                                                ctx.strokeStyle = String(Color.popups.border)
                                                ctx.beginPath()
                                                ctx.arc(
                                                    centerX,
                                                    centerY,
                                                    radius,
                                                    0,
                                                    Math.PI * 2
                                                )
                                                ctx.stroke()
                                            }

                                            ctx.fillStyle = String(Color.popups.text)
                                            ctx.font = "bold 16px " + String(root.uiFont)
                                            ctx.textAlign = "center"
                                            ctx.fillText(
                                                omaState.formatDurationPrecise(typing + idle),
                                                centerX,
                                                centerY + 5
                                            )
                                        }
                                    }

                                    MouseArea {
                                        id: donutHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    Rectangle {
                                        visible: donutHover.containsMouse
                                        z: 20
                                        width: donutTooltipText.implicitWidth + 16
                                        height: 44
                                        radius: 4
                                        color: Color.popups.background
                                        border.width: 1
                                        border.color: Color.popups.border
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 0

                                        Text {
                                            id: donutTooltipText
                                            anchors.centerIn: parent
                                            readonly property var stats: omaState.analyticsPeriodStats(root.analyticsGraphView)
                                            text: "Typing " + omaState.formatDurationPrecise(stats.typingSeconds) + "\nIdle " + omaState.formatDurationPrecise(stats.idleSeconds)
                                            color: Color.popups.text
                                            font.family: root.uiFont
                                            font.pixelSize: 9
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Style.space(4)

                                    Text {
                                        text: "TYPING VS IDLE"
                                        color: Color.muted
                                        font.family: root.uiFont
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        readonly property var stats:
                                            omaState.analyticsPeriodStats(
                                                root.analyticsGraphView
                                            )

                                        text:
                                            "Typing   " +
                                            omaState.formatDuration(stats.typingSeconds)

                                        color: root.vizPrimary
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        readonly property var stats:
                                            omaState.analyticsPeriodStats(
                                                root.analyticsGraphView
                                            )

                                        text:
                                            "Idle     " +
                                            omaState.formatDuration(stats.idleSeconds)

                                        color: root.vizSecondary
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        readonly property var stats:
                                            omaState.analyticsPeriodStats(
                                                root.analyticsGraphView
                                            )

                                        text:
                                            stats.typingPercent.toFixed(0) + "% typing"
                                        color: root.vizPrimary
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── TYPING / IDLE BY PERIOD ──
                            Column {
                                width: parent.width
                                spacing: Style.space(6)

                                Text {
                                    text: "TYPING ACTIVITY"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    id: activityChart

                                    width: parent.width
                                    height: 120

                                    readonly property var series:
                                        omaState.analyticsActivitySeries(root.analyticsGraphView)

                                    readonly property real maxValue:
                                        activityChart.series.reduce(
                                            function(maximum, item) {
                                                return Math.max(
                                                    maximum,
                                                    Number(item.typingSeconds) +
                                                    Number(item.idleSeconds)
                                                )
                                            },
                                            1
                                        )

                                    Row {
                                        anchors.fill: parent
                                        anchors.bottomMargin: 16
                                        spacing: Style.space(4)

                                        Repeater {
                                            model: activityChart.series

                                            delegate: Item {
                                                width:
                                                    (activityChart.width -
                                                     (activityChart.series.length - 1) * Style.space(4))
                                                    / activityChart.series.length
                                                height: activityChart.height - 16

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter

                                                    width: Math.max(7, parent.width * 0.56)

                                                    height:
                                                        Math.max(
                                                            2,
                                                            (parent.height - 20) *
                                                            (
                                                                (
                                                                    Number(modelData.typingSeconds) +
                                                                    Number(modelData.idleSeconds)
                                                                ) /
                                                                activityChart.maxValue
                                                            )
                                                        )

                                                    radius: 3
                                                    color: root.vizSecondary

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.bottom: parent.bottom

                                                        height:
                                                            parent.height *
                                                            (
                                                                Number(modelData.typingSeconds) /
                                                                Math.max(
                                                                    1,
                                                                    Number(modelData.typingSeconds) +
                                                                    Number(modelData.idleSeconds)
                                                                )
                                                            )

                                                        radius: 3
                                                        color: root.vizPrimary
                                                    }
                                                }

                                                Text {
                                                    anchors.bottom: parent.bottom
                                                    anchors.bottomMargin: 12
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: omaState.formatDurationPrecise(Number(modelData.typingSeconds) + Number(modelData.idleSeconds))
                                                    color: Color.muted
                                                    font.family: root.uiFont
                                                    font.pixelSize: 8
                                                }

                                                Text {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter

                                                    text: modelData.label
                                                    color: Color.muted
                                                    font.family: root.uiFont
                                                    font.pixelSize: 9
                                                }

                                                MouseArea {
                                                    id: activityHover
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                }

                                                Rectangle {
                                                    visible: activityHover.containsMouse
                                                    z: 20
                                                    width: activityTooltipText.implicitWidth + 16
                                                    height: 44
                                                    radius: 4
                                                    color: Color.popups.background
                                                    border.width: 1
                                                    border.color: Color.popups.border
                                                    x: Math.max(0, Math.min(parent.width - width, (parent.width - width) / 2))
                                                    y: 0

                                                    Text {
                                                        id: activityTooltipText
                                                        anchors.centerIn: parent
                                                        text: "Typing " + omaState.formatDurationPrecise(modelData.typingSeconds) + "\nIdle " + omaState.formatDurationPrecise(modelData.idleSeconds)
                                                        color: Color.popups.text
                                                        font.family: root.uiFont
                                                        font.pixelSize: 9
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── WORDS HEATMAP ──
                            Column {
                                width: parent.width
                                spacing: Style.space(6)

                                Text {
                                    text: "WORDS HEATMAP"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    text: omaState.analyticsHeatmapMonth(omaState.analyticsAnchor).monthLabel
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 9
                                }

                                Item {
                                    id: heatmapGrid
                                    width: parent.width
                                    height: 190

                                    readonly property var heatmap:
                                        omaState.analyticsHeatmapMonth(omaState.analyticsAnchor)

                                    function weekLabel(week) {
                                        for (let i = 0; i < week.length; ++i) {
                                            if (week[i].inMonth) {
                                                const p = String(week[i].key).split("-")
                                                return p.length === 3 ? String(Number(p[2])) : ""
                                            }
                                        }
                                        return ""
                                    }

                                    Column {
                                        anchors.fill: parent
                                        spacing: 4

                                        Row {
                                            width: parent.width
                                            height: 16
                                            spacing: 4

                                            Item { width: 30; height: 1 }

                                            Repeater {
                                                model: heatmapGrid.heatmap.weeks

                                                delegate: Item {
                                                    width: 24
                                                    height: 16

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: heatmapGrid.weekLabel(modelData)
                                                        color: root.vizMuted
                                                        font.family: root.uiFont
                                                        font.pixelSize: 8
                                                    }
                                                }
                                            }
                                        }

                                        Repeater {
                                            model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                                            delegate: Row {
                                                property int rowIndex: index
                                                width: parent.width
                                                height: 22
                                                spacing: 4

                                                Text {
                                                    width: 30
                                                    height: parent.height
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: modelData
                                                    color: Color.muted
                                                    font.family: root.uiFont
                                                    font.pixelSize: 8
                                                }

                                                Repeater {
                                                    model: heatmapGrid.heatmap.weeks

                                                    delegate: Item {
                                                        width: 24
                                                        height: 22

                                                        readonly property var cell: modelData[rowIndex]

                                                        Rectangle {
                                                            width: 18
                                                            height: 18
                                                            anchors.centerIn: parent
                                                            radius: 3
                                                            visible: cell.inMonth

                                                            color: root.vizPrimary
                                                            opacity:
                                                                cell.words > 0
                                                                    ? 0.18 +
                                                                      0.82 * Math.sqrt(
                                                                          cell.words /
                                                                          Math.max(
                                                                              1,
                                                                              heatmapGrid.heatmap.maxWords
                                                                          )
                                                                      )
                                                                    : 0.06
                                                        }

                                                        Rectangle {
                                                            width: 18
                                                            height: 18
                                                            anchors.centerIn: parent
                                                            radius: 3
                                                            visible: cell.inMonth && cell.isToday
                                                            color: "transparent"
                                                            border.width: 1
                                                            border.color: root.vizSecondary
                                                        }

                                                        MouseArea {
                                                            id: heatmapHover
                                                            anchors.fill: parent
                                                            enabled: cell.inMonth
                                                            hoverEnabled: true
                                                        }

                                                        Rectangle {
                                                            visible: heatmapHover.containsMouse
                                                            z: 30
                                                            width: heatmapTooltipText.implicitWidth + 14
                                                            height: 34
                                                            radius: 4
                                                            color: Color.popups.background
                                                            border.width: 1
                                                            border.color: root.vizSecondary
                                                            x: Math.max(
                                                                0,
                                                                Math.min(
                                                                    heatmapGrid.width - width,
                                                                    (parent.x + parent.width / 2) - width / 2
                                                                )
                                                            )
                                                            y: -38

                                                            Text {
                                                                id: heatmapTooltipText
                                                                anchors.centerIn: parent
                                                                text:
                                                                    cell.key + "\n" +
                                                                    Number(cell.words).toLocaleString() +
                                                                    " words"
                                                                color: Color.popups.text
                                                                font.family: root.uiFont
                                                                font.pixelSize: 8
                                                                horizontalAlignment: Text.AlignHCenter
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── CONSISTENCY ──
                            Column {
                                id: consistencySection
                                width: parent.width
                                spacing: Style.space(7)

                                Text {
                                    text: "CONSISTENCY"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                readonly property var stats:
                                    omaState.analyticsConsistencyStats(root.analyticsGraphView)

                                Row {
                                    width: parent.width
                                    spacing: Style.space(8)

                                    Item {
                                        width: (parent.width - Style.space(8)) / 2
                                        height: 38

                                        Text {
                                            anchors.top: parent.top
                                            text: "ACTIVE DAYS"
                                            color: Color.muted
                                            font.family: root.uiFont
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.bottom: parent.bottom
                                            text: consistencySection.stats.activeDays + " / " + consistencySection.stats.totalDays
                                            color: Color.popups.text
                                            font.family: root.uiFont
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }

                                    Item {
                                        width: (parent.width - Style.space(8)) / 2
                                        height: 38

                                        Text {
                                            anchors.top: parent.top
                                            text: "LONGEST STREAK"
                                            color: Color.muted
                                            font.family: root.uiFont
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.bottom: parent.bottom
                                            text: consistencySection.stats.longestStreak + " day" + (consistencySection.stats.longestStreak === 1 ? "" : "s")
                                            color: Color.popups.text
                                            font.family: root.uiFont
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: Style.space(8)

                                    Item {
                                        width: (parent.width - Style.space(8)) / 2
                                        height: 38

                                        Text {
                                            anchors.top: parent.top
                                            text: "DAILY AVERAGE"
                                            color: Color.muted
                                            font.family: root.uiFont
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.bottom: parent.bottom
                                            text: consistencySection.stats.averageWords.toFixed(1) + " words"
                                            color: Color.popups.text
                                            font.family: root.uiFont
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }

                                    Item {
                                        width: (parent.width - Style.space(8)) / 2
                                        height: 38

                                        Text {
                                            anchors.top: parent.top
                                            text: "BEST DAY"
                                            color: Color.muted
                                            font.family: root.uiFont
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.bottom: parent.bottom
                                            text: consistencySection.stats.bestDayLabel + " · " + consistencySection.stats.bestDayWords
                                            color: Color.accent
                                            font.family: root.uiFont
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.popups.border
                            }

                            // ── TRACKING ──
                            Column {
                                width: parent.width
                                spacing: Style.space(7)

                                Text {
                                    text: "TRACKING"
                                    color: Color.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    width: parent.width
                                    height: 22

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7

                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter

                                        border.width: 1
                                        border.color: Color.accent

                                        color:
                                            omaState.trackingMode === "onlyWhenSound"
                                                ? Color.accent
                                                : "transparent"
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 22
                                        anchors.verticalCenter: parent.verticalCenter

                                        text: "Only when sound effects are enabled"

                                        color: Color.popups.text
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: omaState.setTrackingMode("onlyWhenSound")
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 22

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7

                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter

                                        border.width: 1
                                        border.color: Color.accent

                                        color:
                                            omaState.trackingMode === "always"
                                                ? Color.accent
                                                : "transparent"
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 22
                                        anchors.verticalCenter: parent.verticalCenter

                                        text: "Whenever OmaVibes is enabled"

                                        color: Color.popups.text
                                        font.family: root.uiFont
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: omaState.setTrackingMode("always")
                                    }
                                }

                                Text {
                                    width: parent.width
                                    wrapMode: Text.WordWrap

                                    text:
                                        "Analytics stay on this device. " +
                                        "Typed content is never stored."

                                    color: Color.muted
                                    opacity: 0.85

                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                Connections {
                    target: omaState

                    function onDailyWordsChanged() {
                        typingCanvas.requestPaint()
                        donutCanvas.requestPaint()
                    }

                    function onDailyTypingSecondsChanged() {
                        typingCanvas.requestPaint()
                        donutCanvas.requestPaint()
                    }

                    function onDailyTrackedSecondsChanged() {
                        donutCanvas.requestPaint()
                    }

                    function onAnalyticsAnchorChanged() {
                        typingCanvas.requestPaint()
                        donutCanvas.requestPaint()
                    }
                }

Connections {
    target: root

    function onAnalyticsGraphViewChanged() {
        typingCanvas.requestPaint()
        donutCanvas.requestPaint()
    }
}
                }
            }
        }
    }

