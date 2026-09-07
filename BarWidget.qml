import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "hypr.looks"

  readonly property string applyScript: Qt.resolvedUrl("apply.sh").toString().replace("file://", "")
  readonly property string presetPath: Qt.resolvedUrl("presets.json").toString().replace("file://", "")
  readonly property string savePresetsScript: Qt.resolvedUrl("save-presets.sh").toString().replace("file://", "")
  property int rounding: 10
  property real activeOpacity: 0.86
  property real inactiveOpacity: 0.78
  property bool blurEnabled: true
  property int blurSize: 11
  property int blurPasses: 2
  property int innerGap: 3
  property int outerGap: 8
  property bool applyPending: false
  property var presets: ({})
  property string selectedPreset: "custom"

  function currentValues() {
    return { rounding: root.rounding, activeOpacity: root.activeOpacity,
      inactiveOpacity: root.inactiveOpacity, blurEnabled: root.blurEnabled,
      blurSize: root.blurSize, blurPasses: root.blurPasses,
      innerGap: root.innerGap, outerGap: root.outerGap }
  }

  function valuesMatch(a, b) {
    if (!a || !b) return false
    return a.rounding === b.rounding
      && Math.abs(Number(a.activeOpacity) - Number(b.activeOpacity)) < 0.005
      && Math.abs(Number(a.inactiveOpacity) - Number(b.inactiveOpacity)) < 0.005
      && Boolean(a.blurEnabled) === Boolean(b.blurEnabled)
      && a.blurSize === b.blurSize && a.blurPasses === b.blurPasses
      && a.innerGap === b.innerGap && a.outerGap === b.outerGap
  }

  function loadPresets(raw) {
    try {
      var loaded = JSON.parse(String(raw))
      if (loaded && typeof loaded === "object") root.presets = loaded
      var names = ["minimal", "balanced", "glass"]
      for (var i = 0; i < names.length; i++) {
        if (valuesMatch(root.currentValues(), root.presets[names[i]])) {
          root.selectedPreset = names[i]
          return
        }
      }
    } catch (error) {
      console.warn("hypr.looks: unable to load presets", error)
    }
  }

  function setValues(v) {
    if (!v) return
    rounding = Number(v.rounding)
    activeOpacity = Number(v.activeOpacity)
    inactiveOpacity = Number(v.inactiveOpacity)
    blurEnabled = Boolean(v.blurEnabled)
    blurSize = Number(v.blurSize)
    blurPasses = Number(v.blurPasses)
    innerGap = Number(v.innerGap)
    outerGap = Number(v.outerGap)
  }

  function applyPreset(name) {
    selectedPreset = name
    if (name !== "custom") setValues(presets[name])
    applySoon()
  }

  function saveSelectedPreset() {
    if (selectedPreset === "custom") return
    var updated = {}
    for (var key in presets) updated[key] = presets[key]
    updated[selectedPreset] = currentValues()
    presets = updated
    savePresetsProcess.command = [root.savePresetsScript, JSON.stringify(updated)]
    savePresetsProcess.running = true
  }

  function applySoon() { applyPending = true; applyTimer.restart() }

  Process {
    id: loadPresetsProcess
    command: ["cat", root.presetPath]
    running: true
    stdout: StdioCollector { onStreamFinished: root.loadPresets(text) }
  }

  Process { id: savePresetsProcess; command: [root.savePresetsScript, "{}"] }

  Timer {
    id: applyTimer
    interval: 120
    onTriggered: {
      if (!applyProcess.running) applyProcess.running = true
      else root.applyPending = true
    }
  }

  Process {
    id: applyProcess
    command: [root.applyScript, root.rounding, root.activeOpacity.toFixed(2),
      root.inactiveOpacity.toFixed(2), root.blurEnabled ? "true" : "false",
      root.blurSize, root.blurPasses, root.innerGap, root.outerGap]
    onExited: {
      if (root.applyPending) {
        root.applyPending = false
        applyTimer.restart()
      }
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property bool opened: popup.open
  function open() { popup.open = true }
  function close() { popup.open = false }
  function toggle() { popup.open = !popup.open }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰂘"
    tooltipText: "Hyprland looks"
    onPressed: function(mouseButton) { if (mouseButton === Qt.LeftButton) root.toggle() }
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: false
    contentWidth: Style.space(360)
    contentHeight: contentColumn.implicitHeight + Style.space(28)

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(10)

      Item {
        width: parent.width
        height: Math.max(title.implicitHeight, resetButton.implicitHeight)
        Text {
          id: title
          text: "Hyprland looks"
          color: Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.bold: true
          font.pixelSize: Style.font.title
          anchors.verticalCenter: parent.verticalCenter
        }
        PanelActionButton {
          id: resetButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰑐"
          tooltipText: "Reset to Balanced"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.applyPreset("balanced")
        }
      }

      PanelSectionHeader {
        text: "PRESETS"
        foreground: root.bar ? root.bar.foreground : Color.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
      }

      Row {
        width: parent.width
        spacing: Style.space(6)
        PresetButton { label: "Custom"; selected: root.selectedPreset === "custom"; onClicked: root.applyPreset("custom") }
        PresetButton { label: "Minimal"; selected: root.selectedPreset === "minimal"; onClicked: root.applyPreset("minimal") }
        PresetButton { label: "Balanced"; selected: root.selectedPreset === "balanced"; onClicked: root.applyPreset("balanced") }
        PresetButton { label: "Glass"; selected: root.selectedPreset === "glass"; onClicked: root.applyPreset("glass") }
        PanelActionButton {
          id: saveButton
          iconText: "󰆓"
          tooltipText: root.selectedPreset === "custom" ? "Custom settings are always saved" : "Save changes to " + root.selectedPreset
          enabled: root.selectedPreset !== "custom"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.saveSelectedPreset()
        }
      }

      PanelSeparator { width: parent.width; foreground: root.bar ? root.bar.foreground : Color.foreground }

      component PresetButton: BorderSurface {
        required property string label
        required property bool selected
        signal clicked()
        width: (contentColumn.width - Style.space(18) - saveButton.width) / 4
        height: Style.space(32)
        radius: Style.cornerRadius
        color: selected
          ? Style.selectedFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent)
          : (mouse.containsMouse ? Style.hoverFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent) : "transparent")
        borderSpec: selected
          ? Border.controlSpec("selected", root.bar ? root.bar.foreground : Color.foreground, Color.accent)
          : (mouse.containsMouse ? Border.controlSpec("hover-cursor", root.bar ? root.bar.foreground : Color.foreground, Color.accent) : Border.none())
        Text {
          anchors.centerIn: parent
          text: parent.label
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: parent.clicked()
        }
      }

      component SettingSlider: Column {
        required property string label
        required property real value
        required property real from
        required property real to
        required property int decimals
        signal changed(real value)
        width: contentColumn.width
        spacing: Style.space(3)
        Item {
          width: parent.width
          height: Math.max(labelText.implicitHeight, valueText.implicitHeight)
          Text {
            id: labelText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: parent.parent.label.toUpperCase()
            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: parent.parent.decimals === 0
              ? Math.round(panelSlider.value)
              : Math.round(panelSlider.value * 100) + "%"
            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
        PanelSlider {
          id: panelSlider
          bar: root.bar
          width: parent.width
          minimum: parent.from
          maximum: parent.to
          step: parent.decimals === 0 ? 1 : 0.01
          integer: parent.decimals === 0
          value: parent.value
          onMoved: function(v) { parent.changed(v) }
        }
      }

      PanelSectionHeader { text: "WINDOWS"; foreground: root.bar ? root.bar.foreground : Color.foreground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family }
      SettingSlider { label: "Rounding"; value: root.rounding; from: 0; to: 32; decimals: 0; onChanged: function(v) { root.rounding = Math.round(v); root.applySoon() } }
      SettingSlider { label: "Active opacity"; value: root.activeOpacity; from: 0; to: 1; decimals: 2; onChanged: function(v) { root.activeOpacity = v; root.applySoon() } }
      SettingSlider { label: "Inactive opacity"; value: root.inactiveOpacity; from: 0; to: 1; decimals: 2; onChanged: function(v) { root.inactiveOpacity = v; root.applySoon() } }

      Item {
        width: parent.width
        height: blurSwitch.implicitHeight
        Text { text: "BLUR"; color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted; font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
        ToggleSwitch { id: blurSwitch; anchors.right: parent.right; checked: root.blurEnabled; foreground: root.bar ? root.bar.foreground : Color.foreground; onToggled: { root.blurEnabled = !root.blurEnabled; root.applySoon() } }
      }
      SettingSlider { label: "Blur size"; value: root.blurSize; from: 1; to: 30; decimals: 0; onChanged: function(v) { root.blurSize = Math.round(v); root.applySoon() } }
      SettingSlider { label: "Blur passes"; value: root.blurPasses; from: 1; to: 6; decimals: 0; onChanged: function(v) { root.blurPasses = Math.round(v); root.applySoon() } }

      PanelSectionHeader { text: "SPACING"; foreground: root.bar ? root.bar.foreground : Color.foreground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family }
      SettingSlider { label: "Inner gap"; value: root.innerGap; from: 0; to: 30; decimals: 0; onChanged: function(v) { root.innerGap = Math.round(v); root.applySoon() } }
      SettingSlider { label: "Outer gap"; value: root.outerGap; from: 0; to: 40; decimals: 0; onChanged: function(v) { root.outerGap = Math.round(v); root.applySoon() } }
    }
  }
}
