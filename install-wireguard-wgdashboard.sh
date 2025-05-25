#!/bin/bash

set -e

echo "🔧 Debian 12 için WireGuard + WGDashboard kuruluyor..."

# WireGuard kurulumu
echo "📦 WireGuard kuruluyor..."
apt update
apt install -y wireguard curl iptables-persistent python3 python3-pip git

# Varsayılan WireGuard dizini
WG_DIR="/etc/wireguard"
mkdir -p $WG_DIR
cd $WG_DIR

# Key oluşturma
echo "🔐 Anahtarlar oluşturuluyor..."
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

PRIVATE_KEY=$(cat privatekey)
SERVER_IP="10.99.99.1"

# wg0.conf oluştur
cat > $WG_DIR/wg0.conf <<EOF
[Interface]
Address = $SERVER_IP/24
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
PostUp = iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
SaveConfig = true
EOF

# IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# NAT ayarı
iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
netfilter-persistent save

# WireGuard servisi başlat
echo "🚀 WireGuard servisi başlatılıyor..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# WGDashboard kurulumu
echo "🌐 WGDashboard kuruluyor..."
cd /opt
git clone https://github.com/donaldzou/WGDashboard.git
cd WGDashboard
pip3 install -r requirements.txt

# Config ayarları
cat > config.json <<EOF
{
    "wg_conf_path": "/etc/wireguard/wg0.conf",
    "interface": "wg0",
    "listen_port": 10000,
    "username": "admin",
    "password": "admin"
}
EOF

# WGDashboard systemd servisi
cat > /etc/systemd/system/wgdashboard.service <<EOF
[Unit]
Description=WGDashboard
After=network.target

[Service]
WorkingDirectory=/opt/WGDashboard
ExecStart=/usr/bin/python3 /opt/WGDashboard/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Servisi başlat
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wgdashboard
systemctl start wgdashboard

# IP adresini al
IPADDR=$(hostname -I | awk '{print $1}')

echo "✅ Kurulum tamamlandı!"
echo ""
echo "🌍 WGDashboard arayüzüne şu adresten erişebilirsiniz:"
echo "➡️  http://$IPADDR:10000"
echo ""
echo "🔐 Giriş bilgileri:"
echo "Kullanıcı adı: admin"
echo "Şifre: admin"
