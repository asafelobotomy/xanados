# XanadOS ISO

This repository contains the build files for the XanadOS ISO. The package list has been updated to include optional security and performance tools. Gaming packages are now installed on demand rather than as part of the base system.

## Security packages added
- fail2ban
- nmap
- wireshark-qt
- clamav
- rkhunter

## Performance packages added
- tlp
- thermald
- cpupower
- irqbalance
- preload
- earlyoom

`paru` is now included for install scripts.

## Custom gaming installation
From the welcome application you can select individual gaming packages to install. The installer passes the chosen packages to `install_gaming.sh`, which also accepts packages via command line:

```bash
install_gaming.sh steam lutris heroic-games-launcher
```

You can also supply a file containing package names:

```bash
install_gaming.sh -f /path/to/pkglist.txt
```

If no packages are specified, a default set will be installed.
