#!/bin/bash
# xanadOS UFW Gaming Rules Configuration - 2025 Security Update
# Modern firewall rules for gaming with enhanced security and DDoS protection

set -euo pipefail

# Logging configuration
LOG_FILE="/var/log/xanados-ufw-gaming.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting UFW gaming rules configuration..."

# Security check - ensure we're not in a compromised state
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root for UFW configuration"
   exit 1
fi

# Reset UFW to clean state
echo "Resetting UFW to clean configuration..."
ufw --force reset

# Enable UFW with logging
ufw --force enable
ufw logging medium

# Default policies (deny-by-default security model)
ufw default deny incoming
ufw default deny outgoing
ufw default deny forward

# Allow loopback traffic (essential)
ufw allow in on lo
ufw allow out on lo

# DNS resolution (required for gaming)
ufw allow out 53/tcp comment "DNS TCP"
ufw allow out 53/udp comment "DNS UDP"
ufw allow out 853/tcp comment "DNS over TLS"

# NTP for time synchronization (gaming anti-cheat requirement)
ufw allow out 123/udp comment "NTP"

# HTTPS/HTTP for updates and web content
ufw allow out 80/tcp comment "HTTP"
ufw allow out 443/tcp comment "HTTPS"
ufw allow out 8080/tcp comment "HTTP Alt"

# === Steam Platform (2025 Updated Ports) ===
# Steam client communication
ufw allow out 27015:27030/tcp comment "Steam Client TCP"
ufw allow out 27015:27030/udp comment "Steam Client UDP"
ufw allow out 27036:27037/tcp comment "Steam P2P"

# Steam downloads and content delivery
ufw allow out 80/tcp comment "Steam CDN"
ufw allow out 443/tcp comment "Steam HTTPS"
ufw allow out 27014:27050/udp comment "Steam Voice"

# === Gaming Platforms ===
# Epic Games Store
ufw allow out 5222/tcp comment "Epic Games XMPP"
ufw allow out 3478:3480/udp comment "Epic Games STUN"
ufw allow out 5060/udp comment "Epic Games SIP"

# EA Origin/EA App
ufw allow out 3216/tcp comment "EA Origin"
ufw allow out 9960:9969/tcp comment "EA Games"
ufw allow out 1024:1124/tcp comment "EA Download"

# Battle.net (Blizzard)
ufw allow out 3724/tcp comment "Battle.net"
ufw allow out 6113/tcp comment "Battle.net Chat"
ufw allow out 1119/tcp comment "Battle.net"

# Ubisoft Connect
ufw allow out 13000:13010/tcp comment "Ubisoft Connect"
ufw allow out 14000:14016/tcp comment "Ubisoft Games"

# GOG Galaxy
ufw allow out 9001:9006/tcp comment "GOG Galaxy"

# === Popular Games (2025 Active) ===
# Minecraft (various versions)
ufw allow out 25565/tcp comment "Minecraft Java"
ufw allow out 19132:19133/udp comment "Minecraft Bedrock"

# Counter-Strike 2
ufw allow out 27015/tcp comment "CS2 Server"
ufw allow out 27015/udp comment "CS2 UDP"

# Valorant
ufw allow out 8393:8400/tcp comment "Valorant"
ufw allow out 7777:7784/udp comment "Valorant UDP"

# Apex Legends
ufw allow out 1024:65535/udp comment "Apex Legends"

# Fortnite
ufw allow out 9547/tcp comment "Fortnite"
ufw allow out 9548/tcp comment "Fortnite"
ufw allow out 5222/tcp comment "Fortnite XMPP"

# League of Legends
ufw allow out 2099/tcp comment "LoL Spectator"
ufw allow out 5223/tcp comment "LoL Chat"
ufw allow out 8393:8400/tcp comment "LoL Game"

# World of Warcraft
ufw allow out 3724/tcp comment "WoW"
ufw allow out 6012/tcp comment "WoW"
ufw allow out 1119/tcp comment "WoW Auth"

# === Communication Platforms ===
# Discord (updated ranges for 2025)
ufw allow out 443/tcp comment "Discord HTTPS"
ufw allow out 50000:65535/udp comment "Discord Voice/Video"
ufw allow out 6665:6669/tcp comment "Discord IRC"

# TeamSpeak
ufw allow out 9987/udp comment "TeamSpeak Voice"
ufw allow out 10011/tcp comment "TeamSpeak Query"
ufw allow out 30033/tcp comment "TeamSpeak Files"

# === Game Development/Modding ===
# GitHub (for mods and tools)
ufw allow out 22/tcp comment "Git SSH"
ufw allow out 9418/tcp comment "Git Protocol"

# === Security Hardening (2025 Standards) ===
# Rate limiting for potential attack vectors
ufw limit in ssh comment "SSH Brute Force Protection"
ufw limit in 22/tcp comment "SSH Rate Limit"

# Block common attack ports
ufw deny in 135:139/tcp comment "Block NetBIOS"
ufw deny in 445/tcp comment "Block SMB"
ufw deny in 1433/tcp comment "Block MSSQL"
ufw deny in 3389/tcp comment "Block RDP"
ufw deny in 5900:5906/tcp comment "Block VNC"

# Block P2P file sharing (security risk)
ufw deny out 1337/tcp comment "Block BitTorrent"
ufw deny out 6881:6999/tcp comment "Block BitTorrent Range"
ufw deny out 6881:6999/udp comment "Block BitTorrent UDP"

# === Advanced Security Rules ===
# Prevent DNS amplification attacks
ufw deny in from any to any port 53 comment "Block External DNS Queries"

# Block ICMP flood attacks but allow necessary ICMP
ufw allow out icmp comment "Allow Outgoing ICMP"
ufw limit in icmp comment "Limit Incoming ICMP"

# Block IPv6 if not needed (reduces attack surface)
if ! ip -6 route show default >/dev/null 2>&1; then
    echo "IPv6 not configured, blocking IPv6 traffic for security"
    ufw deny in from ::/0
    ufw deny out to ::/0
fi

# === Application-specific rules for Wine/Proton ===
# Windows games through compatibility layers
ufw allow out 6112:6119/tcp comment "Blizzard Legacy"
ufw allow out 47624/tcp comment "Steam Proton"

# === Monitoring and Intrusion Detection ===
# Enable logging for security monitoring
ufw logging full

# Create custom chains for gaming traffic analysis
iptables -N GAMING_LOG 2>/dev/null || true
iptables -A GAMING_LOG -j LOG --log-prefix "GAMING: " --log-level 4
iptables -A GAMING_LOG -j ACCEPT

# === Status and Verification ===
echo "Verifying UFW configuration..."
ufw status numbered

# Security validation
echo "Running security validation checks..."
if ufw status | grep -q "Status: active"; then
    echo "✓ UFW is active and configured"
else
    echo "✗ UFW configuration failed"
    exit 1
fi

# Check for common gaming ports
GAMING_PORTS=("27015" "25565" "3724" "50000")
for port in "${GAMING_PORTS[@]}"; do
    if ufw status | grep -q "$port"; then
        echo "✓ Gaming port $port configured"
    else
        echo "⚠ Gaming port $port not found in rules"
    fi
done

# Final security recommendations
echo ""
echo "=== xanadOS Gaming Firewall - 2025 Security Configuration Complete ==="
echo "Security Features Enabled:"
echo "- Default deny policy with explicit allow rules"
echo "- Rate limiting for attack prevention"
echo "- Gaming-optimized port ranges"
echo "- Modern platform support (Steam, Epic, Battle.net, etc.)"
echo "- Attack surface reduction (blocked dangerous ports)"
echo "- Enhanced logging for security monitoring"
echo ""
echo "Recommendations:"
echo "1. Monitor logs at: $LOG_FILE"
echo "2. Review rules monthly for new games/platforms"
echo "3. Use 'ufw status numbered' to view current rules"
echo "4. Consider enabling fail2ban for additional protection"
echo ""

echo "[$(date '+%Y-%m-%d %H:%M:%S')] UFW gaming rules configuration completed successfully"
