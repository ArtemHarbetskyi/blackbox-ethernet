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

echo "[A] Налаштування NAT (заміни 'eth0' на свій інтернет-інтерфейс, якщо треба)..."
sudo iptables -t nat -A POSTROUTING -s 10.16.0.0/24 -o eth0 -j MASQUERADE

echo "[A] Запуск WireGuard..."
sudo wg-quick up wg0

echo "[A] Готово ✅"
