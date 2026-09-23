/* === This file is part of Calamares - <https://calamares.io> ===
 *
 * SPDX-FileCopyrightText: 2026 NextraOS Contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Calamares is Free Software: see the License-Identifier above.
 *
 */

import io.calamares.core 1.0
import io.calamares.ui 1.0

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3

Item {
    id: rootItem
    width: parent.width
    height: parent.height

    property string androidSystemType: ""

    function updatePackageChoice() {
        var parts = []
        if (androidCheck.checked) {
            if (androidSystemType === "GAPPS")
                parts.push("android-gapps")
            else if (androidSystemType === "VANILLA")
                parts.push("android-vanilla")
        }
        if (windowsCheck.checked) parts.push("windows")
        if (macosCheck.checked) parts.push("macos")
        config.packageChoice = parts.join(",")
    }

    Rectangle {
        anchors.fill: parent
        color: "#f2f2f2"

        Column {
            id: column
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                width: 700
                height: 100
                color: "#ffffff"
                radius: 10
                border.width: 0

                Text {
                    width: 660
                    height: 80
                    anchors.centerIn: parent
                    text: qsTr("NextraOS can run apps from multiple ecosystems.<br/>Select which additional app types you want to enable. Linux apps (APT + Flatpak) are always installed.")
                    font.pointSize: 11
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHLeft
                }
            }

            Rectangle {
                width: 700
                height: androidCheck.checked ? 130 : 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: androidCheck.checked ? "#0bd1f4" : "#e0e0e0"

                Behavior on height { NumberAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    CheckBox {
                        id: androidCheck
                        anchors.verticalCenter: parent.verticalCenter
                        checked: false

                        onCheckedChanged: {
                            if (checked && rootItem.androidSystemType === "")
                                androidTypeDialog.openForSelection(false)
                            updatePackageChoice()
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - androidCheck.width - 15
                        spacing: 2

                        Row {
                            spacing: 8

                            Text {
                                text: qsTr("Android Apps (Waydroid)")
                                font.pointSize: 12
                                font.bold: true
                                color: "#333333"
                            }

                            Text {
                                visible: androidCheck.checked && rootItem.androidSystemType !== ""
                                text: qsTr("(change type)")
                                font.pointSize: 9
                                color: "#0bd1f4"
                                font.underline: true

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: androidTypeDialog.openForSelection(true)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Run Android applications natively via Waydroid container. Requires installed system (not available in live mode).")
                            font.pointSize: 9
                            color: "#666666"
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: androidCheck.checked && rootItem.androidSystemType !== ""
                            text: {
                                if (rootItem.androidSystemType === "GAPPS")
                                    return qsTr("Type: GAPPS — includes Google Play services (Google license terms apply). ~1.4 GB download.")
                                return qsTr("Type: VANILLA — no Google apps. Clean for redistribution and commercial use. ~0.8 GB download.")
                            }
                            font.pointSize: 8
                            color: "#0bd1f4"
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: androidCheck.checked && rootItem.androidSystemType === ""
                            text: qsTr("Waiting for image type selection…")
                            font.pointSize: 8
                            color: "#e6a23c"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                width: 700
                height: windowsCheck.checked ? 125 : 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: windowsCheck.checked ? "#0bd1f4" : "#e0e0e0"

                Behavior on height { NumberAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    CheckBox {
                        id: windowsCheck
                        anchors.verticalCenter: parent.verticalCenter
                        checked: false

                        onCheckedChanged: updatePackageChoice()
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - windowsCheck.width - 15
                        spacing: 2

                        Text {
                            text: qsTr("Windows Apps (QEMU/KVM)")
                            font.pointSize: 12
                            font.bold: true
                            color: "#333333"
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Run Windows applications in a virtual machine via QEMU/KVM. Additional ~32 GB storage recommended.")
                            font.pointSize: 9
                            color: "#666666"
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: windowsCheck.checked
                            text: qsTr("Windows ISO is downloaded from the Microsoft CDN. Please review the Microsoft Software License Terms (EULA) before installation. NextraOS is not affiliated with Microsoft.")
                            font.pointSize: 8
                            color: "#e6a23c"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                width: 700
                height: macosCheck.checked ? 135 : 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: macosCheck.checked ? "#0bd1f4" : "#e0e0e0"

                Behavior on height { NumberAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    CheckBox {
                        id: macosCheck
                        anchors.verticalCenter: parent.verticalCenter
                        checked: false

                        onCheckedChanged: updatePackageChoice()
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - macosCheck.width - 15
                        spacing: 2

                        Text {
                            text: qsTr("macOS Apps (Experimental)")
                            font.pointSize: 12
                            font.bold: true
                            color: "#333333"
                        }

                        Text {
                            width: parent.width
                            text: qsTr("Run macOS applications in a virtual machine. Requires AVX2-capable CPU. Experimental status.")
                            font.pointSize: 9
                            color: "#666666"
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            visible: macosCheck.checked
                            text: qsTr("macOS Recovery is downloaded from the Apple CDN. Please review the Apple Software License Agreement (EULA). Virtualization on non-Apple hardware is restricted by Apple's EULA. NextraOS is not affiliated with Apple.")
                            font.pointSize: 8
                            color: "#e6a23c"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                width: 700
                height: 30
                color: "#f2f2f2"
                border.width: 0

                Text {
                    height: 30
                    anchors.centerIn: parent
                    text: qsTr("Select additional ecosystems to install, or proceed with Linux apps only.")
                    font.pointSize: 9
                    color: "#888888"
                }
            }
        }
    }

    Dialog {
        id: androidTypeDialog
        property string selectedType: ""
        property bool reselecting: false

        title: qsTr("Choose Android image type")
        modal: true
        width: 560
        height: 360
        anchors.centerIn: parent
        closePolicy: Popup.NoAutoClose

        function openForSelection(isReselect) {
            reselecting = isReselect
            syncFromSelection()
            open()
        }

        function syncFromSelection() {
            selectedType = rootItem.androidSystemType
            vanillaRadio.checked = (selectedType === "VANILLA")
            gappsRadio.checked = (selectedType === "GAPPS")
        }

        onAboutToShow: syncFromSelection()

        background: Rectangle {
            color: "#ffffff"
            radius: 10
            border.width: 1
            border.color: "#dddddd"
        }

        header: Item {
            height: 48
            width: parent ? parent.width : 560

            Text {
                anchors.centerIn: parent
                text: androidTypeDialog.title
                font.pointSize: 13
                font.bold: true
                color: "#333333"
            }
        }

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: qsTr("Waydroid can run with or without Google apps. Choose one — both are supported, neither is required.")
                font.pointSize: 10
                color: "#555555"
                wrapMode: Text.WordWrap
            }

            ButtonGroup {
                id: androidTypeGroup
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 95
                color: "#fafafa"
                radius: 8
                border.width: androidTypeDialog.selectedType === "VANILLA" ? 2 : 1
                border.color: androidTypeDialog.selectedType === "VANILLA" ? "#0bd1f4" : "#dddddd"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RadioButton {
                        id: vanillaRadio
                        ButtonGroup.group: androidTypeGroup
                        onClicked: androidTypeDialog.selectedType = "VANILLA"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: qsTr("VANILLA")
                            font.pointSize: 11
                            font.bold: true
                            color: "#333333"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("No Google apps. Cleaner licensing for redistribution and commercial use.")
                            font.pointSize: 9
                            color: "#666666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 95
                color: "#fafafa"
                radius: 8
                border.width: androidTypeDialog.selectedType === "GAPPS" ? 2 : 1
                border.color: androidTypeDialog.selectedType === "GAPPS" ? "#0bd1f4" : "#dddddd"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RadioButton {
                        id: gappsRadio
                        ButtonGroup.group: androidTypeGroup
                        onClicked: androidTypeDialog.selectedType = "GAPPS"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: qsTr("GAPPS")
                            font.pointSize: 11
                            font.bold: true
                            color: "#333333"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Includes Google Play services. Google license terms apply. Not recommended for commercial redistribution.")
                            font.pointSize: 9
                            color: "#666666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            onAccepted: {
                if (androidTypeDialog.selectedType === "")
                    return
                rootItem.androidSystemType = androidTypeDialog.selectedType
                rootItem.updatePackageChoice()
                androidTypeDialog.close()
            }

            onRejected: {
                if (!androidTypeDialog.reselecting) {
                    rootItem.androidSystemType = ""
                    if (androidCheck.checked)
                        androidCheck.checked = false
                }
                rootItem.updatePackageChoice()
                androidTypeDialog.close()
            }

            Component.onCompleted: {
                var okBtn = button(DialogButtonBox.Ok)
                if (okBtn) {
                    okBtn.enabled = Qt.binding(function() {
                        return androidTypeDialog.selectedType !== ""
                    })
                }
            }
        }
    }
}
