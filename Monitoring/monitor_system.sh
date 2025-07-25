#!/bin/bash

# === CONFIG ===
NOW=$(date +"%d%m%y%H%M%S")
LOG_DIR="/home/reception/Desktop/Monitoring/logs"
LOG_FILE="$LOG_DIR/monitor_log_$NOW.csv"
PING_HOST="https://bacheca.cemambiente.it/"  # Sostituisci con la tua pagina
IFACE="eth0"  # Cambia in wlan0 se usi Wi-Fi

mkdir -p "$LOG_DIR"

# === HEADER CSV ===
if [ ! -f "$LOG_FILE" ]; then
    echo "Timestamp,CPU Temp (°C),CPU Freq (MHz),Load 1m,Load 5m,Load 15m,CPU Usage (%),RAM Total (MB),RAM Used (MB),RAM Free (MB),SWAP Used (MB),Disk Used (%),Disk Read (KB/s),Disk Write (KB/s),Uptime,Throttled,Processes,Net RX (KB/s),Net TX (KB/s),Ping (ms),Ping Success,Connessioni Attive" >> "$LOG_FILE"
fi

# === FUNZIONI ===

get_cpu_usage() {
    top -bn2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8}'
}

get_io_stats() {
    iostat -d /dev/mmcblk0 1 2 | tail -n2 | head -n1 | awk '{print $3","$4}'
}

get_net_stats() {
    RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    RX_KB=$(( (RX2 - RX1) / 1024 ))
    TX_KB=$(( (TX2 - TX1) / 1024 ))
    echo "$RX_KB,$TX_KB"
}

# === MONITOR LOOP ===
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    TEMP=$(vcgencmd measure_temp | egrep -o '[0-9.]+')
    CPU_FREQ=$(vcgencmd measure_clock arm | awk -F= '{print int($2/1000000)}')
    LOAD=$(cat /proc/loadavg | awk '{print $1","$2","$3}')
    CPU_USAGE=$(get_cpu_usage)
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEM_FREE=$(free -m | awk '/Mem:/ {print $4}')
    SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
    DISK_USED=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')
    IO_STATS=$(get_io_stats)
    UPTIME=$(uptime -p | sed 's/up //')
    THROTTLED=$(vcgencmd get_throttled | cut -d= -f2)
    PROC_COUNT=$(ps aux | wc -l)
    NET_STATS=$(get_net_stats)
    CONN_ATTIVE=$(ss -tun | tail -n +2 | wc -l)

    # === PING HTTP ===
    PING_MS=$(curl -o /dev/null -s -w %{time_total}\\n "$PING_HOST")
    if [ $? -eq 0 ]; then
        PING_STATUS="OK"
    else
        PING_STATUS="FAIL"
        echo "[$TIMESTAMP] Ping fallito verso $PING_HOST" >> "$LOG_DIR/ping_errors.log"
        PING_MS="0"
    fi

    # === SCRITTURA CSV ===
    echo "$TIMESTAMP,$TEMP,$CPU_FREQ,$LOAD,$CPU_USAGE,$MEM_TOTAL,$MEM_USED,$MEM_FREE,$SWAP_USED,$DISK_USED,$IO_STATS,$UPTIME,$THROTTLED,$PROC_COUNT,$NET_STATS,$PING_MS,$PING_STATUS,$CONN_ATTIVE" >> "$LOG_FILE"

    sleep 60
done
