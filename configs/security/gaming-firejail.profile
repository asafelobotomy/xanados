# xanadOS Gaming Security Configuration
# Balanced approach: High performance + Security

# Firejail Gaming Profiles
# These profiles sandbox gaming applications while maintaining performance

# Steam with performance optimizations
include /etc/firejail/steam.profile
# Performance tweaks for Steam
private-dev no
private-tmp no
noroot no
caps.drop all
seccomp
net none no
shell none

# Wine/Lutris security profile
include /etc/firejail/wine.profile
private-dev no
private-tmp no
caps.drop all
seccomp.drop @mount,@swap,@reboot,@module
noroot

# General gaming application template
include /etc/firejail/disable-common.inc
include /etc/firejail/disable-passwdmgr.inc
include /etc/firejail/disable-programs.inc

# Allow gaming performance requirements
caps.drop all
no3d no
nodvd no
nogroups no
nonewprivs no
noroot
notv no
nou2f no
novideo no
protocol unix,inet,inet6,netlink
seccomp !chroot
shell none

# Gaming directories access
whitelist ${HOME}/Games
whitelist ${HOME}/.local/share/Steam
whitelist ${HOME}/.wine
whitelist ${HOME}/.lutris

# System access for gaming
read-only /usr/share/hwdata
read-only /sys/devices/pci*
read-only /proc/version
read-only /proc/cpuinfo
read-only /proc/meminfo
