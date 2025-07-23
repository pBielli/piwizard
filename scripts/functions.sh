#!/bin/bash

check_error() {
    if [ $? -ne 0 ]; then
        handle_error "$1"
        return 1
    fi
}
handle_error() {
    handle_print "ERRORE" "$1"
}
handle_print() {
    # Ottieni data e ora
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    if [[ "LOG_NO_COLOR" == "true" ]]; then

        echo -e "[$timestamp][$1] $2"

    else
        local DEFAULT='\033[0;37m' # Grigio
        local RED='\033[0;31m'     # Rosso
        local GREEN='\033[0;32m'   # Verde
        local YELLOW='\033[0;33m'  # Giallo
        local WHITE='\033[0;97m'   # Bianco
        local CYAN='\033[0;96m'    # Ciano
        local NC='\033[0m'         # Reset colore

        local COLOR
        local TEXT_COLOR

        if [[ "$DEBUG" != "true" && "$1" == "DEBUG" ]]; then
            return 0
        fi

        case "$1" in
        "ERRORE")
            COLOR=$RED
            TEXT_COLOR=$YELLOW
            ;;
        "WARNING")
            COLOR=$YELLOW
            TEXT_COLOR=$WHITE
            ;;
        "INFO")
            COLOR=$CYAN
            TEXT_COLOR=$DEFAULT
            ;;
        "OK")
            COLOR=$GREEN
            TEXT_COLOR=$DEFAULT
            ;;
        "DEBUG")
            COLOR=$WHITE
            TEXT_COLOR=$CYAN
            ;;
        *)
            COLOR=$WHITE
            TEXT_COLOR=$DEFAULT
            ;;
        esac

        echo -e "[$timestamp]${COLOR}[$1]${NC} ${TEXT_COLOR}$2${NC}"
    fi

}

LOGO_HBP="false"
printLogo() {
    if [[ "$LOGO_HBP" == "false" || "$1" == "true" ]]; then
        echo -e "$completeAsciiLogo\n"
        LOGO_HBP="true"
    fi
    return 0
}
generateLogFile() {
    # Se ACTUAL_LOG_FILE è già settato, non nullo e non vuoto, ritorna quello
    if [ -z "$ACTUAL_LOG_FILE" ]; then
        local interface=$(ip link | grep -m 1 'wl' | awk '{print $2}' | tr -d ':')
        
        # Ottieni data e ora
        local timestamp=$(date +"%Y%m%d-%H%M%S")

        # Ottieni MAC address dell'interfaccia Wi-Fi (sostituisci wlan0 se diverso)
        local mac_address=$(cat /sys/class/net/$interface/address 2>/dev/null | tr -d ':')

        # Fallback se non trova MAC
        if [ -z "$mac_address" ]; then
            mac_address="unknownMAC"
        fi

        # Crea nome file log
        ACTUAL_LOG_FILE="$LOG_FOLDER/${timestamp}-${mac_address}-log.txt"
    fi
    # Ritorna il path generato
    echo "$ACTUAL_LOG_FILE"
}

# Funzione per generare file di log
init_log() {
    log_file=$(generateLogFile)
    # Se il nome non è valido (vuoto), segnala errore
    if [ -z "$log_file" ]; then
        handle_print "ERRORE" "Impossibile generare il file di log"
        return 1
    fi
    # Se il file esiste già, esce silenziosamente
    if [ -f "$log_file" ]; then
        return 0
    fi
    handle_print "INFO" "Operazione avviata. Log salvati in $log_file"
    # Crea directory dei log se non esiste
    mkdir -p "$LOG_FOLDER"
    return 0
}
# Funzione per eseguire comandi e salvare i log
run_with_logs() {
    local command="$1"
    local log_file="$2"
    
    # Esegui il comando, stampa sulla console con colori, ma salva su file senza codici colore
    {
        handle_print "INFO" "Esecuzione di: $command"
        eval "$command"
        local result=$?
        if [ $result -eq 0 ]; then
            handle_print "OK" "Operazione completata con successo"
        else
            handle_print "ERRORE" "Operazione fallita con codice di errore $result"
        fi
    } 2>&1 | tee >(stdbuf -oL grep -E "INFO|ERRORE|OK|DEBUG" >&2) | sed -r 's/\x1B\[[0-9;]*[mK]//g' >>"$log_file"
    
    echo
    handle_print "INFO" "Premi un tasto per continuare..."
    read -n 1 -s
}

# Funzione per mostrare le variabili
show_variables() {
    # Estrai tutte le variabili attualmente dichiarate
    vars=$(compgen -v)
    handle_print "INFO" "=== VARIABILI DI CONFIGURAZIONE ==="
    
    # Cicla e stampa nome e contenuto
    for var in $vars; do
        # Filtra solo variabili rilevanti (quelle in maiuscolo o specifiche del sistema)
        if [[ "$var" =~ ^[A-Z_]+$ || "$var" =~ ^(APP_DIR|SCRIPT_DIR|ASSETS_DIR|LOG_FOLDER)$ ]]; then
            value="${!var}"
            handle_print "INFO" "$var=\"$value\""
        fi
    done
}
handle_reboot(){
    sec=${1:-10}  # Imposta a 10 se $1 non è passato
    handle_print "INFO" "Premi 'r' entro $sec secondi per annullare il riavvio..."

    read -t $sec -n 1 -s tasto

    if [ "$tasto" = "r" ]; then
        handle_print "INFO" "Riavvio annullato."
    else
        handle_print "INFO" "Riavvio in corso..."
        sleep 2
        sudo reboot
    fi
}
get_wifi_interface() {
    local interface=$(ip link | grep -m 1 'wl' | awk '{print $2}' | tr -d ':')
    if [[ -z "$interface" ]]; then
        handle_error "Interfaccia Wi-Fi non trovata"
        return 1
    fi
    echo "$interface"
}

ensure_wifi_is_up() {
    local wifi_interface=$(get_wifi_interface)
    check_error "Interfaccia Wi-Fi non trovata" || return 1

    if [[ $(sudo ip link show "$wifi_interface" | grep 'state DOWN') ]]; then
        handle_print "INFO" "Interfaccia Wi-Fi '$wifi_interface' è spenta, la accendo..."
        sudo ip link set "$wifi_interface" up
        sleep 2 # Wait for the interface to come up
    else
        handle_print "INFO" "Interfaccia Wi-Fi '$wifi_interface' è attiva."
    fi
}

connect_wifi() {
    rfkill unblock all
    local wifi_interface=$(get_wifi_interface)
    check_error "Interfaccia Wi-Fi non trovata" || return 1

    ensure_wifi_is_up
    check_error "Interfaccia Wi-Fi spenta" || return 1

    if [[ -n "$WIFI_SSID" && -n "$WIFI_PASSWORD" && -n "$WIFI_COUNTRY" ]]; then
        handle_print "INFO" "Configuro Wi-Fi SSID='$WIFI_SSID'..."

        sudo bash -c "cat > /etc/wpa_supplicant/wpa_supplicant.conf" <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=$WIFI_COUNTRY

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
}
EOF

        sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
        sudo systemctl restart wpa_supplicant
        sudo systemctl restart dhcpcd
        sudo wpa_cli -i "$wifi_interface" reconfigure

        handle_print "INFO" "Attendo connessione Wi-Fi..."
        sleep 10
        local attempts=0
        local max_attempts=60 # Increased wait time
        while ! iw "$wifi_interface" link | grep -q 'Connected'; do
            sleep 5 # Increased sleep duration
            ((attempts++))
            if ((attempts >= max_attempts)); then
                handle_error "Connessione Wi-Fi fallita dopo $((attempts * 5)) secondi"
                return 1
            fi
        done

        handle_print "OK" "Wi-Fi connesso, verifico IP..."

        attempts=0
        max_attempts=10

        while true; do
            ip_addr=$(ip -4 addr show "$wifi_interface" | awk '/inet / { print $2 }')
            if [[ -n "$ip_addr" ]]; then
                mac_addr=$(ip link show "$wifi_interface" | awk '/link\/ether/ { print $2 }')
                handle_print "INFO" "IP assegnato: $ip_addr"
                handle_print "INFO" "MAC address: $mac_addr"
                break
            fi

            sleep 5
            ((attempts++))

            if ((attempts >= max_attempts)); then
                handle_error "Nessun IP ottenuto dopo $((attempts * 5)) secondi"
                sudo systemctl restart dhcpcd
                return 1
            fi
        done

        return 0
    else
        handle_error "SSID, PASSWORD o Country Wi-Fi mancanti"
        return 1
    fi
}

create_user() {
    # Verifica se le variabili necessarie sono definite
    if [ -z "$USERNAME" ]; then
        handle_error "La variabile USERNAME non è definita."
        return 1
    fi

    if [ -z "$PASSWORD" ]; then
        handle_error "La variabile PASSWORD non è definita."
        return 1
    fi

    handle_print "INFO" "Creazione del nuovo utente: $USERNAME"

    # Verifica se l'utente esiste già
    if id "$USERNAME" &>/dev/null; then
        handle_error "L'utente $USERNAME esiste già nel sistema."
        return 1
    else
        # Creazione del nuovo utente
        sudo useradd -m -s /bin/bash "$USERNAME"
        check_error "Errore durante la creazione dell'utente $USERNAME." || return 1

        # Imposta la password per il nuovo utente
        echo "$USERNAME:$PASSWORD" | sudo chpasswd
        check_error "Errore durante l'impostazione della password per l'utente $USERNAME." || return 1

        handle_print "OK" "Utente $USERNAME creato con successo."
    fi

    # Aggiungi l'utente al gruppo sudo
    handle_print "INFO" "Aggiunta dell'utente $USERNAME al gruppo sudo"
    sudo usermod -aG sudo "$USERNAME"
    check_error "Errore durante l'aggiunta dell'utente $USERNAME al gruppo sudo." || return 1
    handle_print "OK" "Utente $USERNAME aggiunto al gruppo sudo con successo."

    # Configura l'autologin
    handle_print "INFO" "Configurazione dell'autologin per l'utente $USERNAME"

    # Verifica quale sistema di display manager è in uso
    if [ -f /etc/lightdm/lightdm.conf ]; then
        # Configurazione per LightDM (comune in Raspbian con GUI)
        sudo sed -i "s/^#autologin-user=.*$/autologin-user=$USERNAME/" /etc/lightdm/lightdm.conf
        sudo sed -i "s/^autologin-user=.*$/autologin-user=$USERNAME/" /etc/lightdm/lightdm.conf

        # Se la stringa autologin-user non esiste, aggiungila alla sezione [Seat:*]
        if ! grep -q "autologin-user=" /etc/lightdm/lightdm.conf; then
            sudo sed -i "/^\[Seat:\*\]/a autologin-user=$USERNAME" /etc/lightdm/lightdm.conf
        fi

        # Assicurati che autologin-user-timeout sia impostato a 0
        sudo sed -i "s/^#autologin-user-timeout=.*$/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf
        sudo sed -i "s/^autologin-user-timeout=.*$/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf

        # Se la stringa autologin-user-timeout non esiste, aggiungila
        if ! grep -q "autologin-user-timeout=" /etc/lightdm/lightdm.conf; then
            sudo sed -i "/autologin-user=$USERNAME/a autologin-user-timeout=0" /etc/lightdm/lightdm.conf
        fi

        # Assicurati che il gruppo autologin esista e aggiungi l'utente ad esso
        sudo groupadd -f autologin
        sudo gpasswd -a "$USERNAME" autologin
    elif [ -d /etc/systemd/system/getty@tty1.service.d ]; then
        # Configurazione per systemd
        sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
        echo "[Service]" | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null
        echo "ExecStart=" | sudo tee -a /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null
        echo "ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM" | sudo tee -a /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null
        sudo systemctl daemon-reload
    else
        handle_error "Impossibile configurare l'autologin. Sistema di display manager non riconosciuto."
        return 1
    fi

    handle_print "OK" "Autologin configurato con successo per l'utente $USERNAME."

    return 0
}

set_hostname() {
    [[ "$SET_HOSTNAME" == "true" && -n "$HOSTNAME" ]] && {
        handle_print "INFO" "Imposto hostname: $HOSTNAME"
        echo "$HOSTNAME" | sudo tee /etc/hostname
        sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
    }
}

setup_ssh() {
    [[ "$ENABLE_SSH" == "true" ]] && {
        handle_print "INFO" "Abilito SSH..."
        sudo systemctl enable ssh
        sudo systemctl start ssh
        [[ -n "$SSH_KEY" ]] && {
            sudo mkdir -p /home/"$USERNAME"/.ssh
            echo "$SSH_KEY" | sudo tee -a /home/"$USERNAME"/.ssh/authorized_keys
            sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
            sudo chmod 700 /home/"$USERNAME"/.ssh
            sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
        }
    }
}

setup_ftp() {
    [[ "$ENABLE_FTP" == "true" ]] && {
        handle_print "INFO" "Installo FTP server..."
        sudo apt install -y vsftpd || handle_error "Installazione FTP fallita"
        sudo systemctl enable vsftpd
        sudo systemctl start vsftpd
    }
}

setup_vnc() {
    [[ "$ENABLE_VNC" == "true" ]] && {
        handle_print "INFO" "Abilito VNC..."
        sudo raspi-config nonint do_vnc 0
    }
}

set_boot_logo() {
    [[ "$CHANGE_BOOT_LOGO" == "true" && -f "$BOOT_LOGO_PATH" ]] && {
        handle_print "INFO" "Cambio logo di boot..."
        sudo cp "$BOOT_LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png || handle_error "Copia logo fallita"
    }
}

set_background() {
    if [[ "$CHANGE_BACKGROUND" == "true" && -f "$BACKGROUND_PATH" ]]; then
        handle_print "INFO" "Cambio sfondo desktop..."

        # local DEST_IMG="/usr/share/rpd-wallpaper/$(basename "$BACKGROUND_PATH")"
        local DEST_IMG="/usr/share/rpd-wallpaper/clouds.jpg"
        #genero hash dell'immagine per confrontare se viene sostituita correttamente
        hash1=$(sha256sum "$DEST_IMG" | awk '{print $1}')

        #copio immagine dentro la cartella degli sfondi
        handle_print "INFO" "Copio nuovo sfondo dentro la cartella degli sfondi..."
        mv "$DEST_IMG" "$DEST_IMG.bk"
        check_error "Errore durante il bk dell'immagine default. $BACKGROUND_PATH -> $DEST_IMG." || return 1
        cp "$BACKGROUND_PATH" "$DEST_IMG"
        check_error "Errore durante la copia dell'immagine. $BACKGROUND_PATH -> $DEST_IMG." || return 1
        chown "root:root" "$DEST_IMG"
        check_error "Errore l'attribuzione del proprietario all'immagine. $DEST_IMG." || return 1
        chmod 664 "$DEST_IMG"
        check_error "Errore l'attribuzione dei permessi all'immagine. $DEST_IMG." || return 1
        handle_print "OK" "Sfondo impostato con successo."

        hash2=$(sha256sum "$DEST_IMG" | awk '{print $1}')

        if [ "$hash1" = "$hash2" ]; then
            handle_error "I file sono IDENTICI"
        else
            handle_print "OK" "I file sono DIVERSI"
        fi
    else
        handle_print "INFO" "Cambio sfondo disabilitato."
        return 0
    fi
}

setup_apps() {
    if [[ -n "$APPS_TO_INSTALL" ]]; then
        handle_print "INFO" "Installo app necessarie..."
        sudo apt install -y $APPS_TO_INSTALL || handle_error "Installazione apps fallita"
    fi
}
setup_autostart() {
    if [[ -d "$AUTOSTART_DIR" ]]; then
        handle_print "INFO" "Setup dei file di autostart..."
        sudo cp "$AUTOSTART_DIR"/* /etc/xdg/autostart/ || handle_error "Copia cartella autostart fallita"
        sudo chmod 755 /etc/xdg/autostart/* # Ensure executable permissions
    fi
}
update_system() {
    [[ "$UPDATE_SYSTEM" == "true" ]] && {
        handle_print "INFO" "Update sistema..."
        sudo apt update -y || handle_error "Update fallito"
    }
    [[ "$UPGRADE_SYSTEM" == "true" ]] && {
        handle_print "INFO" "Upgrade sistema..."
        sudo apt upgrade -y || handle_error "Upgrade fallito"
    }

    [[ "$REMOVE_UNUSED_PACKAGES" == "true" ]] && {
        handle_print "INFO" "Pulizia pacchetti inutili..."
        sudo apt autoremove -y
        sudo apt autoclean
    }
    [[ -n "$DISABLE_SERVICES" ]] && {
        handle_print "INFO" "Disabilito servizi: $DISABLE_SERVICES"
        for service in $DISABLE_SERVICES; do
            sudo systemctl disable "$service" || handle_error "Disabilitazione $service fallita"
        done
    }
}
set_keyboard_layout() {
    if [ -z "$KEYBOARD_LAYOUT" ]; then
        handle_error "La variabile KEYBOARD_LAYOUT non è definita."
        return 1
    fi

    handle_print "INFO" "Impostazione della lingua della tastiera a: $KEYBOARD_LAYOUT"

    # Aggiorna il file di configurazione di systemd-localed
    sudo sed -i "s/^XKBLAYOUT=.*$/XKBLAYOUT=\"$KEYBOARD_LAYOUT\"/" /etc/default/keyboard
    if [ $? -ne 0 ]; then
        handle_error "Errore durante la modifica del file di configurazione della tastiera."
        return 1
    fi

    # Applica le modifiche
    sudo udevadm trigger --subsystem-match=input --action=change
    if [ $? -ne 0 ]; then
        handle_error "Errore durante l'applicazione delle modifiche."
        return 1
    fi

    handle_print "OK" "Lingua della tastiera impostata con successo a: $KEYBOARD_LAYOUT"
    return 0
}
disable_screen_saver() {
    if [ "$DISABLE_SCREEN_SAVER" != "true" ]; then

        handle_print "INFO" "Disabilito sospensione dello schermo..."
        # Installa x11-xserver-utils se non presente (necessario per xset)
        sudo apt install -y x11-xserver-utils
        check_error "Installazione x11-xserver-utils fallita" || return 1

        # Modifica il file lightdm.conf
        sudo sed -i '/^\[Seat:\*\]/a xserver-command=X -s 0 -dpms' /etc/lightdm/lightdm.conf
        check_error "Errore durante la configurazione di lightdm.conf per disabilitare la sospensione dello schermo." || return 1

        # Modifica il file autostart
        sudo tee -a /etc/xdg/lxsession/LXDE-pi/autostart >/dev/null <<EOF
@xset s off
@xset -dpms
@xset s noblank
EOF
        check_error "Errore durante la configurazione di autostart per disabilitare la sospensione dello schermo." || return 1

        handle_print "OK" "Sospensione dello schermo disabilitata con successo."
        return 0
    fi
}
set_audio_hdmi() {
    if [[ "$ENABLE_HDMI_AUDIO" != "true" ]]; then
        handle_print "INFO" "Abilitazione audio HDMI disabilitata (ENABLE_HDMI_AUDIO != true)."
        return 0
    fi

    handle_print "INFO" "Imposto audio su uscita HDMI..."

    # Esempio di comando per impostare audio su HDMI (per ALSA)
    amixer cset numid=3 65536
    check_error "Impostazione audio HDMI fallita" || return 1

    handle_print "OK" "Audio impostato su HDMI con successo."
    return 0
}
setup_display_standby() {
    if [[ "$DISPLAY_STANDBY" == "false" ]]; then
        handle_print "INFO" "Disabilito standby del display..."
        xset s off
        xset -dpms
        xset s noblank
    else
        handle_print "INFO" "Standby display abilitato o non modificato (DISPLAY_STANDBY=\"$DISPLAY_STANDBY\")"
    fi
}
install_app() {
# === ESECUZIONE ORDINATA ===
handle_print "INFO" "Avvio installer..."

connect_wifi || exit 1
create_user
set_keyboard_layout
update_system
setup_ssh
setup_ftp
setup_vnc
setup_apps
setup_autostart
set_boot_logo
set_background
set_hostname
disable_screen_saver
set_audio_hdmi
setup_display_standby
handle_print "INFO" "Installazione completata."
exit 0
}
