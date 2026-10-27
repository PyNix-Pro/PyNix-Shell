import QtQuick
import QtQuick.Layouts

RowLayout {
    id: row

    property string title: ""
    property string description: ""
    default property alias controlData: controls.data

    Layout.fillWidth: true
    spacing: 20

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            Layout.fillWidth: true
            text: row.title
            color: palette.primaryText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            text: row.description
            color: palette.secondaryText
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }
    }

    RowLayout {
        id: controls
        spacing: 8
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    required property var palette
}
