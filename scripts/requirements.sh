#!/bin/bash

# Ottiene il percorso del file sorgente (funziona anche se lo script viene "source"-ato)
SOURCE="${BASH_SOURCE[0]}"

# Ciclo per risolvere eventuali link simbolici (symlink) allo script
while [ -h "$SOURCE" ]; do
  # Determina la directory che contiene il link simbolico
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

  # Risolve il vero path del file a cui punta il link
  SOURCE="$(readlink "$SOURCE")"

  # Se il link è relativo, lo converte in assoluto basandosi su $DIR
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done

# Determina la directory finale e reale che contiene lo script (non un link)
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}") #"$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# Determina la directory "app", che si trova un livello sopra a "scripts"
APP_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
ASSETS_DIR="$APP_DIR/assets"
set -a
source "$ASSETS_DIR/default_configs.env"
source "$APP_DIR/configs.env"
source "$SCRIPT_DIR/functions.sh"
source "$ASSETS_DIR/imgs/ascii_logo.env" # Inserisci il percorso corretto per il file di configurazione o variabili
set +a
