#!/bin/bash

set -e

echo "\U0001F527 Installing WireGuard and WGDashboard with Domain Support on Debian 12..."

# Step 1: Install required packages
echo "\U0001F4E6 Installing required packages..."
apt update
apt install -y wireguard iptables-persistent python3 python3-pip git

# Step 2: Create WireGuard keys and configuration
WG_DIR="/etc/wireguard"
mkdir -p $WG_DIR
cd $WG_DIR

echo "\U0001F510 Generating WireGuard keys..."
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

PRIVATE_KEY=$(cat privatekey)
SERVER_IP="10.99.99.1"

cat > wg0.conf <<EOF
[Interface]
Address = $SERVER_IP/24
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
PostUp = iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
SaveConfig = true
EOF

# Step 3: Enable IP forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Step 4: Setup NAT
iptables -t nat -A POSTROUTING -s 10.99.99.0/24 -o eth0 -j MASQUERADE
netfilter-persistent save

# Step 5: Enable WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0 || {
    echo "❌ WireGuard service failed to start. Check your wg0.conf and system logs.";
    exit 1;
}

# Step 6: Install WGDashboard
cd /opt
rm -rf WGDashboard
sudo git clone https://github.com/donaldzou/WGDashboard.git
cd WGDashboard

# Step 7: Install Python requirements
REQUIREMENTS_PATH="/opt/WGDashboard/src/requirements.txt"
if [ ! -f "$REQUIREMENTS_PATH" ]; then
    echo "❌ ERROR: requirements.txt not found at $REQUIREMENTS_PATH. Repo may have changed. Aborting."
    exit 1
fi
pip3 install --break-system-packages -r "$REQUIREMENTS_PATH"

# Step 8: Create config.json
mkdir -p /opt/WGDashboard/src
cat > /opt/WGDashboard/src/config.json <<EOF
{
  "wg_conf_path": "/etc/wireguard/wg0.conf",
  "interface": "wg0",
  "listen_port": 10000,
  "username": "admin",
  "password": "admin"
}
EOF

# Step 9: Create systemd service
cat > /etc/systemd/system/wgdashboard.service <<EOF
[Unit]
Description=WGDashboard Web UI
After=network.target

[Service]
WorkingDirectory=/opt/WGDashboard/src
ExecStart=/usr/bin/python3 /opt/WGDashboard/src/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Step 10: Enable and start the dashboard
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wgdashboard
systemctl start wgdashboard

# Step 11: Output dashboard info
IPADDR=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ WireGuard and WGDashboard have been successfully installed!"
echo "\U0001F30D Access the dashboard at: http://$IPADDR:10086"
echo "\U0001F512 Login: admin / admin"
echo ""
echo "⚠️ IMPORTANT:"
echo "If you plan to use a domain (e.g., vpn.example.com), make sure to create an A record pointing to $IPADDR with Cloudflare Proxy DISABLED (grey cloud)."
