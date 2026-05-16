#!/bin/bash

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
  echo "Lütfen bu scripti 'sudo' ile çalıştırın: sudo ./install.sh"
  exit
fi

# O anki aktif X11 kullanıcısını bul
X_USER=$(who | grep '(:[0-9])' | awk '{print $1}' | head -n 1)
if [ -z "$X_USER" ]; then
    X_USER=$(loginctl list-sessions | grep "seat0" -B 5 | grep "Active=yes" -B 5 | grep -oP '(?<=UID=)\d+' | xargs id -un 2>/dev/null)
fi
[ -z "$X_USER" ] && X_USER=${SUDO_USER:-$USER}

USER_HOME=$(getent passwd "$X_USER" | cut -d: -f6)

echo "--- Kurulum Başlıyor ($X_USER için) ---"

# 1. Eski Servisleri Durdur ve Temizle
echo "[1/4] Eski servisler temizleniyor..."
systemctl stop mcnd-monitor.service 2>/dev/null
systemctl disable mcnd-monitor.service 2>/dev/null
rm -f /etc/systemd/system/mcnd-monitor.service

# 2. Bağımlılıkları Yükle
echo "[2/4] Bağımlılıklar yükleniyor..."
apt update && apt install -y python3-pip python3-tk x11-xserver-utils
pip3 install pynput --break-system-packages 2>/dev/null || pip3 install pynput

# 3. Scripti Kopyala ve Sudoers Yetkisi Ver
cp mcnd_monitor.py /usr/local/bin/mcnd_monitor.py
chmod +x /usr/local/bin/mcnd_monitor.py
echo "$X_USER ALL=(ALL) NOPASSWD: /bin/systemctl stop mcnd.service, /bin/systemctl start mcnd.service" > /etc/sudoers.d/mcnd-monitor

# 4. GÖRÜNMEZ Otomatik Başlatma Oluştur
echo "[4/4] Görünmez otomatik başlatma ayarlanıyor..."
mkdir -p /etc/xdg/autostart
cat <<EOF > /etc/xdg/autostart/mcnd-monitor.desktop
[Desktop Entry]
Type=Application
Exec=/usr/bin/python3 /usr/local/bin/mcnd_monitor.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=MCND Monitor
Comment=Mouse Trigger for MCND
EOF

chown "$X_USER:$X_USER" /usr/local/bin/mcnd_monitor.py

echo "--- Kurulum Tamamlandı! ---"
echo "Şimdi bilgisayarı yeniden başlatabilirsin veya oturumu kapatıp açabilirsin."
echo "Script ARKA PLANDA, GÖRÜNMEZ bir şekilde çalışacaktır."
