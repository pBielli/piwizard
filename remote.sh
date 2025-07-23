#!/usr/bin/env bash
set -e

# Cartella temporanea
TMP_DIR=$(mktemp -d)

echo "[INFO] Scarico la repo in $TMP_DIR ..."
curl -L https://github.com/pBielli/piwizard/archive/refs/heads/main.zip -o "$TMP_DIR/repo.zip"

echo "[INFO] Estraggo i file..."
unzip -q "$TMP_DIR/repo.zip" -d "$TMP_DIR"

# Cartella estratta ha nome piwizard-main
cd "$TMP_DIR/piwizard-main"

echo "[INFO] Eseguo run.sh ..."
chmod +x run.sh
./run.sh

# Pulizia finale
echo "[INFO] Pulizia..."
rm -rf "$TMP_DIR"

echo "[INFO] Completato!"
