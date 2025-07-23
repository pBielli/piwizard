#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/scripts/requirements.sh"

printLogo
init_log

handle_print "INFO" "Avvio installazione automatica e salvataggio dei log in $log_file..."

# Esegui lo script, stampa sulla console con colori, ma salva su file senza codici colore
run_with_logs "install_app" "$log_file"

handle_reboot 10