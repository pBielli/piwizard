#!/bin/bash
# Script di gestione menu principale
source "$(dirname "${BASH_SOURCE[0]}")/scripts/requirements.sh"


# Funzione per mostrare il menu
show_menu() {
    clear
    printLogo "true"
    echo "============================================="
    echo "               MENU PRINCIPALE               "
    echo "============================================="
    echo "1. Installa app"
    echo "2. Configura Wi-Fi"
    echo "3. Crea nuovo utente"
    echo "4. Imposta hostname"
    echo "5. Configura SSH"
    echo "6. Configura FTP"
    echo "7. Configura VNC"
    echo "8. Imposta logo di boot"
    echo "9. Imposta sfondo desktop"
    echo "10. Imposta layout tastiera"
    echo "11. Imposta HDMI come uscita audio"
    echo "12. Disabilita screen saver"
    echo "13. Disabilita sospensione schermo se HDMI scollegato"
    echo "14. Configura Chromium"
    echo "15. Aggiorna sistema"
    echo "20. Mostra variabili di configurazione"
    echo "0. Esci"
    echo "============================================="
    echo "Seleziona un'opzione: "
}
# Main
while true; do
    show_menu
    read -r choice

    case $choice in
    0)
        handle_print "INFO" "Uscita dal programma"
        exit 0
        ;;
    1)
        init_log
        handle_print "INFO" "Opzione selezionata: Installa app" | tee -a "$log_file"
        run_with_logs "install_app" "$log_file"
        ;;
    2)
        init_log
        handle_print "INFO" "Opzione selezionata: Configura Wi-Fi" | tee -a "$log_file"
        run_with_logs "connect_wifi" "$log_file"
        ;;
    3)
        init_log
        handle_print "INFO" "Opzione selezionata: Crea nuovo utente" | tee -a "$log_file"
        run_with_logs "create_user" "$log_file"
        ;;
    4)
        init_log
        handle_print "INFO" "Opzione selezionata: Imposta hostname" | tee -a "$log_file"

        # Salva il valore originale
        original_set_hostname=$SET_HOSTNAME

        # Forza l'attivazione della funzione
        SET_HOSTNAME="true"

        if [ -z "$HOSTNAME" ]; then
            handle_print "INFO" "Inserisci il nuovo hostname: "
            read -r new_hostname
            HOSTNAME="$new_hostname"
        fi

        run_with_logs "set_hostname" "$log_file"

        # Ripristina il valore originale
        SET_HOSTNAME=$original_set_hostname
        ;;
    5)
        init_log
        handle_print "INFO" "Opzione selezionata: Configura SSH" | tee -a "$log_file"

        # Salva il valore originale
        original_enable_ssh=$ENABLE_SSH

        # Forza l'attivazione della funzione
        ENABLE_SSH="true"

        run_with_logs "setup_ssh" "$log_file"

        # Ripristina il valore originale
        ENABLE_SSH=$original_enable_ssh
        ;;
    6)
        init_log
        handle_print "INFO" "Opzione selezionata: Configura FTP" | tee -a "$log_file"

        # Salva il valore originale
        original_enable_ftp=$ENABLE_FTP

        # Forza l'attivazione della funzione
        ENABLE_FTP="true"

        run_with_logs "setup_ftp" "$log_file"

        # Ripristina il valore originale
        ENABLE_FTP=$original_enable_ftp
        ;;
    7)
        init_log
        handle_print "INFO" "Opzione selezionata: Configura VNC" | tee -a "$log_file"

        # Salva il valore originale
        original_enable_vnc=$ENABLE_VNC

        # Forza l'attivazione della funzione
        ENABLE_VNC="true"

        run_with_logs "setup_vnc" "$log_file"

        # Ripristina il valore originale
        ENABLE_VNC=$original_enable_vnc
        ;;
    8)
        init_log
        handle_print "INFO" "Opzione selezionata: Imposta logo di boot" | tee -a "$log_file"

        # Salva il valore originale
        original_change_boot_logo=$CHANGE_BOOT_LOGO

        # Forza l'attivazione della funzione
        CHANGE_BOOT_LOGO="true"

        if [ -z "$BOOT_LOGO_PATH" ] || [ ! -f "$BOOT_LOGO_PATH" ]; then
            handle_print "INFO" "Inserisci il percorso completo del logo di boot: "
            read -r logo_path
            if [ -f "$logo_path" ]; then
                BOOT_LOGO_PATH="$logo_path"
            else
                handle_error "Il file non esiste"
                continue
            fi
        fi

        run_with_logs "set_boot_logo" "$log_file"

        # Ripristina il valore originale
        CHANGE_BOOT_LOGO=$original_change_boot_logo
        ;;
    9)
        init_log
        handle_print "INFO" "Opzione selezionata: Imposta sfondo desktop" | tee -a "$log_file"

        # Salva il valore originale
        original_change_background=$CHANGE_BACKGROUND

        # Forza l'attivazione della funzione
        CHANGE_BACKGROUND="true"

        if [ -z "$BACKGROUND_PATH" ] || [ ! -f "$BACKGROUND_PATH" ]; then
            handle_print "INFO" "Inserisci il percorso completo dell'immagine di sfondo: "
            read -r bg_path
            if [ -f "$bg_path" ]; then
                BACKGROUND_PATH="$bg_path"
            else
                handle_error "Il file non esiste"
                continue
            fi
        fi

        run_with_logs "set_background" "$log_file"

        # Ripristina il valore originale
        CHANGE_BACKGROUND=$original_change_background
        ;;

    10)
        init_log
        handle_print "INFO" "Opzione selezionata: Imposta layout tastiera" | tee -a "$log_file"

        if [ -z "$KEYBOARD_LAYOUT" ]; then
            handle_print "INFO" "Inserisci il layout della tastiera (es. it, en, fr): "
            read -r layout
            KEYBOARD_LAYOUT="$layout"
        fi

        run_with_logs "set_keyboard_layout" "$log_file"
        ;; 
    11)
        init_log
        handle_print "INFO" "Opzione selezionata: HDMI come uscita audio" | tee -a "$log_file"
        original_ENABLE_HDMI_AUDIO=$ENABLE_HDMI_AUDIO
        ENABLE_HDMI_AUDIO="true"
        run_with_logs "set_audio_hdmi" "$log_file"
        ENABLE_HDMI_AUDIO=$original_ENABLE_HDMI_AUDIO
        ;;
    12)
        init_log
        handle_print "INFO" "Opzione selezionata: Disabilita screen saver" | tee -a "$log_file"

        # Salva il valore originale
        original_disable_screen_saver=$DISABLE_SCREEN_SAVER

        # Forza l'attivazione della funzione
        DISABLE_SCREEN_SAVER="true"

        run_with_logs "disable_screen_saver" "$log_file"

        # Ripristina il valore originale
        DISABLE_SCREEN_SAVER=$original_disable_screen_saver
        ;;

    13)
        init_log
        handle_print "INFO" "Opzione selezionata: Disabilita sospensione schermo se HDMI scollegato" | tee -a "$log_file"
        original_DISPLAY_STANDBY=$DISPLAY_STANDBY
        DISPLAY_STANDBY="false"
        run_with_logs "setup_display_standby" "$log_file"
        DISPLAY_STANDBY=$original_DISPLAY_STANDBY
        ;;  
    14)
        init_log
        handle_print "INFO" "Opzione selezionata: Configura Chromium" | tee -a "$log_file"

        if [ -z "$AUTOSTART_DIR" ] || [ ! -d "$AUTOSTART_DIR" ]; then
            handle_print "INFO" "Inserisci il percorso della directory autostart: "
            read -r autostart_dir
            if [ -d "$autostart_dir" ]; then
                AUTOSTART_DIR="$autostart_dir"
            else
                handle_error "La directory non esiste"
                continue
            fi
        fi

        run_with_logs "setup_chromium" "$log_file"
        ;;
    15)
        init_log
        handle_print "INFO" "Opzione selezionata: Aggiorna sistema" | tee -a "$log_file"

        # Salva i valori originali
        original_update_system=$UPDATE_SYSTEM
        original_upgrade_system=$UPGRADE_SYSTEM
        original_remove_unused=$REMOVE_UNUSED_PACKAGES

        # Menu di aggiornamento sistema
        echo "Scegli l'operazione di aggiornamento:"
        echo "1. Solo aggiornamento (apt update)"
        echo "2. Aggiornamento e upgrade (apt update && apt upgrade)"
        echo "3. Aggiornamento completo (update, upgrade e pulizia)"
        read -r update_choice

        case $update_choice in
        1)
            UPDATE_SYSTEM="true"
            UPGRADE_SYSTEM="false"
            REMOVE_UNUSED_PACKAGES="false"
            ;;
        2)
            UPDATE_SYSTEM="true"
            UPGRADE_SYSTEM="true"
            REMOVE_UNUSED_PACKAGES="false"
            ;;
        3)
            UPDATE_SYSTEM="true"
            UPGRADE_SYSTEM="true"
            REMOVE_UNUSED_PACKAGES="true"
            ;;
        *)
            handle_error "Scelta non valida"
            continue
            ;;
        esac

        run_with_logs "update_system" "$log_file"

        # Ripristina i valori originali
        UPDATE_SYSTEM=$original_update_system
        UPGRADE_SYSTEM=$original_upgrade_system
        REMOVE_UNUSED_PACKAGES=$original_remove_unused
        ;;
    20)
        init_log
        handle_print "INFO" "Opzione selezionata: Mostra variabili di configurazione" | tee -a "$log_file"
        show_variables | tee -a "$log_file"
        echo
        handle_print "INFO" "Premi un tasto per continuare..."
        read -n 1 -s
        ;;
    
    *)
        handle_print "ERRORE" "Opzione non valida"
        sleep 2
        ;;
    esac
done
