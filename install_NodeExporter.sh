#!/bin/bash

# ÃœberprÃ¼fen, ob das Skript mit root-Rechten ausgefÃ¼hrt wird
if [ "$EUID" -ne 0 ]; then
    echo "Dieses Skript muss mit root-Rechten ausgefÃ¼hrt werden. Bitte verwenden Sie sudo oder fÃ¼hren Sie es als Root aus."
    exit 1
fi

# ÃœberprÃ¼fen auf notwendige Programme
if ! command -v wget &> /dev/null; then
    echo "Installation von wget benötigt."
    exit 1
fi

# Node Exporter Version die geladen werden soll
NODE_EXPORTER_VERSION="latest"

# Zielverzeichnis
INSTALL_DIR="/usr/share/node_exporter"

# Systemd Service Datei
SYSTEMD_SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Erstellen Sie das Installationsverzeichnis, falls es nicht existiert
mkdir -p "$INSTALL_DIR"

# Herunterladen und Entpacken des Node Exporters
if [ "$NODE_EXPORTER_VERSION" = "latest" ]; then
    LATEST_VERSION=$(wget -qO- https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep -oP '"tag_name": "\K(.*?)(?=")')
    NODE_EXPORTER_VERSION=${LATEST_VERSION#v}
fi
wget "https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
tar xvfz "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"


# Kopieren Sie die Dateien in das Installationsverzeichnis
cp "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter" "$INSTALL_DIR"

# Berechtigungen festlegen
chown -R root:root "$INSTALL_DIR"

# Erstellen der Systemd Service Datei
echo "[Unit]" > "$SYSTEMD_SERVICE_FILE"
echo "Description=Node Exporter" >> "$SYSTEMD_SERVICE_FILE"
echo "After=network.target" >> "$SYSTEMD_SERVICE_FILE"
echo "" >> "$SYSTEMD_SERVICE_FILE"
echo "[Service]" >> "$SYSTEMD_SERVICE_FILE"
echo "ExecStart=$INSTALL_DIR/node_exporter" >> "$SYSTEMD_SERVICE_FILE"
echo "" >> "$SYSTEMD_SERVICE_FILE"
echo "[Install]" >> "$SYSTEMD_SERVICE_FILE"
echo "WantedBy=default.target" >> "$SYSTEMD_SERVICE_FILE"

# Systemd neu laden
systemctl daemon-reload

# Node Exporter als Dienst starten und aktivieren
systemctl start node_exporter
systemctl enable node_exporter

# AufrÃ¤umen: Entfernen von heruntergeladene Tar-Archiven und das entpackte Verzeichnis
rm "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
rm -r "node_exporter-$NODE_EXPORTER_VERSION.linux-amd64"

echo "Node Exporter wurde erfolgreich installiert und als Dienst eingerichtet."
