#!/bin/bash

set -e

echo "[B] Встановлення залежностей..."
sudo apt update
sudo apt install -y wireguard iptables dnsmasq

echo "[B] Генерація ключів (якщо потрібно)..."
[[ -f ~/wg_privatekey ]] || wg genkey | tee ~/wg_privatekey | wg pubkey > ~/wg_publickey

# Введіть вручну публічний ключ з A
read -p "[B] Введіть публічний ключ GroundStation (A): " A_PUBLIC_KEY

PRIVATE_KEY=$(cat ~/wg_privatekey)

read -p "[B] Введіть IP GroundStation у wfb-тунелі (наприклад 10.0.0.1): " GS_WFB_IP

echo "[B] Створення /etc/wireguard/wg0.conf"
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.16.0.2/24
PrivateKey = $PRIVATE_KEY

[Peer]
PublicKey = $A_PUBLIC_KEY
Endpoint = $GS_WFB_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 15
EOF

echo "[B] Запуск WireGuard..."
sudo wg-quick up wg0

echo "[B] Включення IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1

echo "[B] Налаштування NAT через wg0..."
sudo iptables -t nat -A POSTROUTING -s 192.168.88.0/24 -o wg0 -j MASQUERADE

echo "[B] Налаштування dnsmasq (DHCP-сервер)..."
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=eth0
dhcp-range=192.168.88.10,192.168.88.100,12h
server=1.1.1.1
EOF

sudo systemctl restart dnsmasq

echo "[B] Налаштування eth0 з IP 192.168.88.1/24"
sudo ip addr flush dev eth0
sudo ip addr add 192.168.88.1/24 dev eth0
sudo ip link set eth0 up

# Встановити iptables-persistent (без інтерфейсу)
echo "[INFO] Встановлюю iptables-persistent..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Зберегти поточні правила
echo "[INFO] Зберігаю iptables правила..."
sudo netfilter-persistent save

echo "[DONE] Готово. Правила збережено і будуть застосовані після перезавантаження."



echo "[B] Готово ✅ — Підключіть клієнт до Ethernet!"
