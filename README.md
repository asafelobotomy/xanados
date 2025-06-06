# XanadOS

[![Build Status](https://github.com/asafelobotomy/xanados/actions/workflows/build.yml/badge.svg)](https://github.com/asafelobotomy/xanados/actions)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Screenshots](#screenshots)

## Features

- 🎮 Gaming-ready stack with Steam and Lutris
- 🧼 Minimal install option for a clean KDE Plasma setup
- 💻 Next.js web frontend for downloads and updates
- 🛡️ Secure Boot detection with toggle
- 🧠 Custom PyQt Welcome App for guided installation

## Quick Start

Clone the repository and build the ISO:

```bash
git clone https://github.com/asafelobotomy/xanados.git
cd xanados/xanados-iso
paru -S archiso
sudo mkarchiso -v -o out .
```

## Screenshots

<!-- Add screenshots or GIFs below. Place images in docs/screenshots/ -->
<!-- Example: -->
<!-- ![Welcome App screenshot](docs/screenshots/welcome-app.png) -->

## Repository layout

This repository contains the archiso profile as well as supporting
directories used to build XanadOS.

- [`xanados-iso/`](xanados-iso/) – archiso profile and build scripts
- [`xanados-iso/calamares/`](xanados-iso/calamares/) – Calamares configs
- [`xanados-iso/airootfs/`](xanados-iso/airootfs/) – live environment rootfs
- [`xanados-iso/packages.x86_64`](xanados-iso/packages.x86_64) – package list
- [`bootstrap_pkgs`](xanados-iso/bootstrap_packages.x86_64) – minimal pkgs
- [`xanados-iso/docs/`](xanados-iso/docs/) – additional documentation
- [`packages/`](packages/) – custom PKGBUILDs
- [`scripts/`](scripts/) – automation scripts
- [`configs/`](configs/) – configuration snippets
- [`docs/`](docs/) – project documentation
- [`logs/`](logs/) – build and test logs
- [`frontend/`](frontend/) – Next.js based web frontend

## Building the ISO

1. Install the `archiso` package using Paru:

   ```bash
   paru -S archiso
   ```

2. Clone this repository and enter the profile directory:

   ```bash
   git clone https://github.com/asafelobotomy/xanados.git
   cd xanados/xanados-iso
   ```

3. Run `mkarchiso` or the helper script to create the image.
   The helper script automatically builds any packages found under
   `packages/` and populates `packages/repo` if it is empty. Output will be
   placed in the `out/` directory:

   ```bash
   # direct command
   sudo mkarchiso -v -o out .

   # or use the provided helper
   bash ../scripts/build_iso.sh
   ```

4. Flash the resulting ISO to a USB drive:

   ```bash
   sudo dd if=out/xanados-*.iso of=/dev/sdX bs=4M status=progress && sync
   ```

### Building in Docker

If `mkarchiso` isn't available locally, run the build inside a Docker
container using the provided helper script:

```bash
bash scripts/docker_build_iso.sh
```

This launches an Arch Linux container, installs the required packages,
and produces the ISO in `out/`. Logs are saved to `logs/docker-iso-build.log`.

## Installing XanadOS

1. Boot your machine from the USB stick.
2. On first login the **Welcome App** appears. Pick Gaming, Minimal or
   Recommended to install the desired packages. Logs are saved to
   `/tmp/welcome.log` and the autostart entry is provided by
   `/etc/xanados/welcome.desktop`.
3. Run the Calamares installer from the live session to install the
   system to disk.

For more details see
[`xanados-iso/docs/README_XANADOS.md`](xanados-iso/docs/README_XANADOS.md).

## Running the Next.js frontend

The repository also contains a web-based frontend located in `frontend/`.
Enter that directory before running any of the commands below:

```bash
cd frontend
```

1. Install dependencies:

   ```bash
   npm install
   ```

2. Start the development server:

   ```bash
   npm run dev
   ```

3. Lint the codebase:

   ```bash
   npm run lint
   ```

   ESLint rules are defined in `frontend/.eslintrc.js`.

4. Generate production builds:

   ```bash
   npm run build
   ```

## Testing

Basic Bats tests verify that build scripts exist and are executable.
Run all tests with:

```bash
bats tests
```

## Contributing

Contributions are welcome! Please see
[CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Support & Community

- File issues and feature requests on
  [GitHub Issues](https://github.com/asafelobotomy/xanados/issues)
- Join our discussion board (if available)

## License

This project is licensed under the GNU General Public License v3.0.
See the [LICENSE](LICENSE) file for details.
