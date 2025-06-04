#!/bin/bash

set -e

echo "[A] Встановлення залежностей..."
sudo apt update
sudo apt install -y wireguard iptables

echo "[A] Генерація ключів (якщо потрібно)..."
[[ -f ~/wg_privatekey ]] || wg genkey | tee ~/wg_privatekey | wg pubkey > ~/wg_publickey

# Введіть вручну публічний ключ з B
read -p "[A] Введіть публічний ключ пристрою B (AirStation): " B_PUBLIC_KEY

PRIVATE_KEY=$(cat ~/wg_privatekey)

echo "[A] Створення /etc/wireguard/wg0.conf"
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.16.0.1/24
PrivateKey = $PRIVATE_KEY
ListenPort = 51820

[Peer]
PublicKey = $B_PUBLIC_KEY
AllowedIPs = 10.16.0.2/32
EOF

echo "[A] Увімкнення IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#
# Прочитати інтерфейс
read -p "[A] Введіть назву інтерфейсу, звідки йде інтернет (наприклад, eth0 або wlan0): " INTERFACE_NAME

# Перевірити чи інтерфейс існує
if ! ip link show "$INTERFACE_NAME" > /dev/null 2>&1; then
    echo "[ERROR] Інтерфейс '$INTERFACE_NAME' не знайдено. Вихід."
    exit 1
fi

# Додати iptables правило
echo "[INFO] Додаю iptables правило MASQUERADE..."
sudo iptables -t nat -A POSTROUTING -s 10.16.0.0/24 -o "$INTERFACE_NAME" -j MASQUERADE

# Встановити iptables-persistent (без інтерфейсу)
echo "[INFO] Встановлюю iptables-persistent..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Зберегти поточні правила
echo "[INFO] Зберігаю iptables правила..."
sudo netfilter-persistent save

echo "[DONE] Готово. Правила збережено і будуть застосовані після перезавантаження."
#

echo "[A] Запуск WireGuard..."
sudo wg-quick up wg0

echo "[A] Готово ✅"
