# xanadOS UFW Gaming Firewall Rules
# Gaming-optimized firewall configuration

# Default policies
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# Enable UFW logging (low level for performance)
ufw logging low

# SSH access (if needed)
# ufw allow ssh

# Gaming platforms
# Steam
ufw allow out 27000:27100/udp comment 'Steam Client'
ufw allow out 27015:27030/tcp comment 'Steam'
ufw allow out 27036:27037/tcp comment 'Steam'
ufw allow out 4380/udp comment 'Steam'

# Epic Games
ufw allow out 5222/tcp comment 'Epic Games'
ufw allow out 80,443/tcp comment 'Epic Games HTTPS'

# Battle.net
ufw allow out 80,443,1119/tcp comment 'Battle.net'
ufw allow out 6113/tcp comment 'Battle.net'
ufw allow out 6881:6999/tcp comment 'Battle.net'

# Discord
ufw allow out 50000:65535/udp comment 'Discord Voice'
ufw allow out 80,443/tcp comment 'Discord'

# Common gaming ports
ufw allow out 3478:3480/tcp comment 'Gaming TCP'
ufw allow out 3478:3480/udp comment 'Gaming UDP'
ufw allow out 16384:16403/udp comment 'Gaming Voice'

# Game streaming
# Moonlight/GameStream
ufw allow 47998:48010/tcp comment 'GameStream TCP'
ufw allow 47998:48010/udp comment 'GameStream UDP'

# Steam Remote Play
ufw allow 27031:27036/tcp comment 'Steam Remote Play'
ufw allow 27031:27036/udp comment 'Steam Remote Play'

# Enable UFW
ufw --force enable
