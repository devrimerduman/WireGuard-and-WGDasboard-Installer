#!/bin/bash

set -e

echo "🔧 Installing WireGuard and WGDashboard on Debian 12..."

# Step 1: Install dependencies
echo "📦 Installing required packages..."
apt update
apt install -y wireguard curl iptables-persistent python3 python3-pip git

# Step 2: Generate WireGuard keys
WG_DIR="/etc/wireguard"
mkdir -p $WG_DIR
cd $WG_DIR

echo "🔐 Generating WireGuard private and public keys..."
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

PRIVATE_KEY=$(cat privatekey)
SERVER_IP="10.99.99.1"

# Step 3: Create wg0.conf
cat > $WG_DIR/wg0.conf <<EOF
[Interface]
Address = $SERVER_IP/24
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
PostUp = iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
SaveConfig = true
EOF

# Step 4: Enable IP forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Step 5: Configure NAT
echo "Setting up NAT masquerading..."
iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
netfilter-persistent save

# Step 6: Enable and start WireGuard
echo "🚀 Starting WireGuard service..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Step 7: Install WGDashboard
echo "🌐 Installing WGDashboard..."
cd /opt
git clone https://github.com/donaldzou/WGDashboard.git
cd WGDashboard
pip3 install --break-system-packages -r requirements.txt

# Step 8: Configure WGDashboard
cat > config.json <<EOF
{
    "wg_conf_path": "/etc/wireguard/wg0.conf",
    "interface": "wg0",
    "listen_port": 10000,
    "username": "admin",
    "password": "admin"
}
EOF

# Step 9: Create systemd service for WGDashboard
cat > /etc/systemd/system/wgdashboard.service <<EOF
[Unit]
Description=WGDashboard Web UI
After=network.target

[Service]
WorkingDirectory=/opt/WGDashboard
ExecStart=/usr/bin/python3 /opt/WGDashboard/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Step 10: Enable and start WGDashboard
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wgdashboard
systemctl start wgdashboard

# Step 11: Get public IP address
IPADDR=$(hostname -I | awk '{print $1}')

# Final message
echo ""
echo "✅ WireGuard and WGDashboard installation is complete!"
echo ""
echo "🌍 You can access WGDashboard at:"
echo "➡️  http://$IPADDR:10000"
echo ""
echo "🔐 Default credentials:"
echo "Username: admin"
echo "Password: admin"
