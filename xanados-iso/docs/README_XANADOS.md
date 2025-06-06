# XanadOS ISO v2

XanadOS is a custom Arch-based Linux distribution tailored for gaming,
privacy, and aesthetic coherence. Built with a modular installer, XanadOS
lets users choose their desired experience — Gaming, Minimal, or Fully
Featured — during first boot.

## Features

- 🎮 Gaming-ready stack (Steam, Lutris, MangoHud, Heroic, etc.)
- 🧼 Minimal install option for clean KDE Plasma environment
- 🧠 Full recommended setup including multimedia and productivity apps
- 🛡️ Secure Boot toggle and detection
- 💻 Custom Welcome App built in PyQt5 with:
  - Frameless window design
  - Fade-in animation and button hover effects
  - Real-time installation logging
  - Progress bar and threading support
  - Auto-disable after first run

## How to Use

1. Boot the ISO
2. On first login, the **Welcome App** will start
3. Choose an install mode and follow the instructions
4. System will install selected packages and log output to `/tmp/welcome.log`

## Directory Layout

- `/etc/xanados/` – Scripts and core logic
- `/etc/skel/.config/autostart/` – First login autostart for Welcome App
- `/usr/bin/` – Standard binaries managed via **paru** (pacman wrapper)
