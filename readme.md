# piwizard

Script per l’automazione del setup di Raspberry Pi / sistemi embedded.

---

## 🚀 Scopo

Automatizza il provisioning di sistemi basati su Raspberry Pi, installa dipendenze, configura servizi e prepara il sistema all'uso immediato.

---

## 🧠 Prerequisiti

- Bash (su Raspberry Pi o sistemi Debian-like)
- Permessi `sudo`
- Connessione Internet

---

## ⚙️ Funzionamento

1. Clona la repository sul Raspberry Pi:
   ```bash
   git clone https://github.com/pBielli/piwizard.git
   cd piwizard
   ```

2. Rendi eseguibili gli script:
   ```bash
   chmod +x *.sh
   ```

3. Esegui lo script principale:
   ```bash
   ./setup.sh [opzioni]
   ```

4. Utilizza altri script modulari come:
   ```bash
   ./install-deps.sh
   ./config.sh
   ```

---

## 🔧 Configurazioni disponibili

Le configurazioni sono gestite in due fasi:

1. ✅ **Default** da: `assets/default_configs.env`
2. 🔄 **Override** opzionale da: `configs.env`

Questo permette di mantenere aggiornati gli script senza perdere personalizzazioni locali.

---

### 📝 Come personalizzare

Crea un file `configs.env` nella root del progetto con solo le variabili che desideri modificare rispetto ai default.

Esempio `configs.env`:

```env
HOSTNAME="reception_pi"
WEB_USERNAME="reception"
WEB_PASSWORD="xxx"
CHANGE_BACKGROUND=true
WIFI_SSID="Wi-cem-Fi"
WIFI_PASSWORD="xxx"
```

---
### 📁 Variabili di sistema predefinite

Queste variabili sono definite automaticamente dal sistema e possono essere utilizzate nelle configurazioni:

| Variabile | Descrizione | Esempio Valore | Utilizzo |
|-----------|-------------|----------------|----------|
| `$APP_DIR` | Directory principale dell'applicazione | `/home/pi/myapp` | Percorso base per file e cartelle dell'app |
| `$SCRIPT_DIR` | Directory contenente gli script | `/home/pi/myapp/scripts` | Percorso degli script di sistema |
| `$ASSETS_DIR` | Directory degli asset (immagini, file) | `/home/pi/myapp/assets` | Percorso per risorse statiche |
| `$LOG_FOLDER` | Directory dei log (se non ridefinita) | `$APP_DIR/logs` | Percorso automatico per i file di log |

> 💡 **Come usarle**: Puoi utilizzare queste variabili nelle tue configurazioni, ad esempio: `BACKGROUND_PATH="$ASSETS_DIR/imgs/my-wallpaper.jpg"`

### 🧩 Variabili supportate

| Variabile | Descrizione | Valore Default/Esempio | Note |
|-----------|-------------|------------------------|------|
| `DEBUG` | Abilita il logging in modalità debug | `true` | Mostra messaggi di debug aggiuntivi |
| `LOG_NO_COLOR` | Disabilita il colore nei log | `false` | Se `true`, rimuove i codici colore ANSI |
| `LOG_FOLDER` | Percorso dove salvare i log | `"$APP_DIR/logs"` | Directory per file di log |
| `AUTOSTART_DIR` | Directory contenente i file di autostart | `"$ASSETS_DIR/autostart"` | File `.desktop` copiati in `/etc/xdg/autostart/` |
| `BOOT_LOGO_PATH` | Percorso del logo di boot personalizzato | `"$ASSETS_DIR/imgs/default-logo.png"` | Sostituisce `/usr/share/plymouth/themes/pix/splash.png` |
| `BACKGROUND_PATH` | Sfondo desktop personalizzato | `"$ASSETS_DIR/imgs/default-wallpaper.jpg"` | Sostituisce `/usr/share/rpd-wallpaper/clouds.jpg` |
| `CHANGE_BOOT_LOGO` | Abilita il cambio del logo di boot | `true` | Richiede `BOOT_LOGO_PATH` valido |
| `CHANGE_BACKGROUND` | Abilita il cambio dello sfondo | `true` | Richiede `BACKGROUND_PATH` valido |
| `KEYBOARD_LAYOUT` | Layout tastiera | `"it"` | Codice layout (it, us, fr, de, etc.) |
| `HOSTNAME` | Nome dell'host | `"raspberrypi"` | Nome identificativo del sistema |
| `SET_HOSTNAME` | Applica `HOSTNAME` al sistema | `true` | Modifica `/etc/hostname` e `/etc/hosts` |
| `USERNAME` | Utente Linux da creare | `"pi"` | ⚠️ **RICHIESTO** - Nome utente sistema |
| `PASSWORD` | Password utente Linux | `"raspberry"` | ⚠️ **RICHIESTO** - Password per l'utente |
| `WIFI_SSID` | Nome della rete WiFi | `"MyNetwork"` | ⚠️ **RICHIESTO** per connessione WiFi |
| `WIFI_PASSWORD` | Password della rete WiFi | `"mypassword"` | ⚠️ **RICHIESTO** per connessione WiFi |
| `WIFI_COUNTRY` | Paese per il modulo WiFi | `"IT"` | Codice ISO paese (IT, US, FR, etc.) |
| `ENABLE_SSH` | Abilita il servizio SSH | `true` | Permette accesso remoto via SSH |
| `SSH_KEY` | Chiave pubblica SSH da autorizzare | `"ssh-rsa AAAA..."` | Opzionale - per accesso senza password |
| `ENABLE_FTP` | Abilita il servizio FTP | `true` | Installa e avvia `vsftpd` |
| `ENABLE_VNC` | Abilita il server VNC | `true` | Permette controllo desktop remoto |
| `APPS_TO_INSTALL` | Pacchetti da installare | `"chromium-browser xdotool unclutter"` | Lista separata da spazi |
| `UPDATE_SYSTEM` | Aggiorna lista pacchetti | `true` | Esegue `apt update` |
| `UPGRADE_SYSTEM` | Aggiorna pacchetti installati | `true` | Esegue `apt upgrade` |
| `REMOVE_UNUSED_PACKAGES` | Rimuove pacchetti non utilizzati | `true` | Esegue `apt autoremove` e `autoclean` |
| `DISABLE_SERVICES` | Servizi da disattivare | `""` | Lista separata da spazi (es: "bluetooth cups") |
| `DISABLE_SCREEN_SAVER` | Disattiva lo screensaver | `true` | Impedisce spegnimento automatico schermo |
| `ENABLE_HDMI_AUDIO` | Forza audio su uscita HDMI | `true` | Configura ALSA per output HDMI |
| `DISPLAY_STANDBY` | Controllo standby display | `false` | Se `false`, disabilita standby con HDMI spento |

> 💡 Alcune variabili sono dipendenti da altre. Ad esempio: `USERNAME` e `PASSWORD` possono essere derivati da `WEB_USERNAME` e `WEB_PASSWORD`.

---

### ✅ Esecuzione

Lo script `setup.sh` caricherà in automatico entrambe le configurazioni:

```bash
./setup.sh
```

oppure puoi sovrascrivere temporaneamente con variabili inline:

```bash
HOSTNAME="testpi" ENABLE_VNC=false ./setup.sh
```

---

## 🪄 Aggiungere nuovi script

1. Crea uno script `.sh` eseguibile.
2. Posizionalo nella root del progetto o in una sottocartella.
3. Richiamalo all’interno di `setup.sh` o manualmente.

---

## 📁 Struttura del progetto

```
piwizard/
├── README.md
├── .gitignore
├── setup.sh
├── install-deps.sh
├── config.sh
└── logs/             ← cartella ignorata dal controllo versioni
```

---

## ✅ Come contribuire

1. Fai un fork del progetto
2. Crea un branch (`feature/il-tuo-nome`)
3. Aggiungi/modifica gli script
4. Aggiorna il README se necessario
5. Fai una pull request

---

## 📄 Licenza

Questo progetto è rilasciato sotto licenza MIT.
