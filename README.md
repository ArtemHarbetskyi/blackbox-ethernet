> ⚠️ Перед запуском потрібно вручну скопіювати публічні/приватні ключі або передати через ssh, або зчитати з файлів.

```
wg genkey | tee privatekey | wg pubkey > publickey
```

# Після запуску скриптів

1. Переконайся, що wfb-ng з'єднує A ↔ B.

2. Запусти скрипти:

```
chmod +x setup_*.sh
./setup_groundstation.sh
./setup_airstation.sh
```

3. Після цього просто втикни кабель у девайс C — і він має отримати інтернет через DHCP!
4. curl ifconfig.me
