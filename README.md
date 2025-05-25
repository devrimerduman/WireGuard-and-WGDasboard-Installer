✅ README.md

# WireGuard + WGDashboard Auto Installer for Debian 12

This repository provides a fully automated Bash script to install and configure **WireGuard** and **WGDashboard** on a Debian 12 server.

## 🚀 Features

- Installs WireGuard VPN server
- Generates server keys and creates `wg0.conf`
- Configures NAT and IP forwarding
- Installs and configures [WGDashboard](https://github.com/donaldzou/WGDashboard)
- Starts both services and enables them on boot
- Outputs the web dashboard address and login credentials

## 🖥️ Requirements

- A fresh **Debian 12** system
- Root access
- An internet connection
- Ports `51820/UDP` and `10000/TCP` open on your firewall/router

## 📦 What It Installs

- `wireguard`
- `python3`, `pip`, `git`
- `iptables-persistent`
- WGDashboard via Git

## ⚙️ How to Use

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/<your-username>/wireguard-autoinstall/main/install-wireguard-wgdashboard.sh

    Replace <your-username> with your actual GitHub username.

    Make it executable:

chmod +x install-wireguard-wgdashboard.sh

    Run the script:

sudo ./install-wireguard-wgdashboard.sh

    After installation, access the dashboard in your browser:

http://<your-server-ip>:10000

Login credentials:

    Username: admin

    Password: admin

🔐 Notes

    By default, the WireGuard server uses 10.99.99.1/24.

    You can change the ListenPort, credentials, or dashboard port in the config.json file (/opt/WGDashboard/config.json).

    The dashboard runs as a systemd service named wgdashboard.

📚 Resources

    WireGuard Quickstart

    WGDashboard GitHub

🛑 Disclaimer

This script is provided "as is" with no warranty. Use it at your own risk and always review the code before executing on production systems.

Created by Devrimer Duman