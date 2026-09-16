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
    width: parent.width
    height: parent.height

    function updatePackageChoice() {
        var parts = []
        if (androidCheck.checked) parts.push("android")
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
                height: 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: androidCheck.checked ? "#0bd1f4" : "#e0e0e0"

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    CheckBox {
                        id: androidCheck
                        anchors.verticalCenter: parent.verticalCenter
                        checked: false

                        onCheckedChanged: updatePackageChoice()
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - androidCheck.width - 15

                        Text {
                            text: qsTr("Android Apps (Waydroid)")
                            font.pointSize: 12
                            font.bold: true
                            color: "#333333"
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
                            visible: androidCheck.checked
                            text: qsTr("~1.4 GB will be downloaded during installation (requires network)")
                            font.pointSize: 8
                            color: "#0bd1f4"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                width: 700
                height: 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: windowsCheck.checked ? "#0bd1f4" : "#e0e0e0"

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
                    }
                }
            }

            Rectangle {
                width: 700
                height: 80
                color: "#ffffff"
                radius: 10
                border.width: 1
                border.color: macosCheck.checked ? "#0bd1f4" : "#e0e0e0"

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
}
