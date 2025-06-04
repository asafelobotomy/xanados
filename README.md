# XanadOS

XanadOS is a cyberpunk-inspired Linux distribution based on Arch Linux. It aims to deliver a gaming focused experience while keeping the system minimal and privacy oriented. A custom PyQt5 "Welcome App" lets you choose between Gaming, Minimal or full Recommended setups as soon as you boot the live environment.

## Features

- Gaming-ready stack with tools like Steam, Lutris, MangoHud and Heroic
- Optional minimal install for a clean KDE Plasma desktop
- Full recommended setup with multimedia and productivity applications
- Secure Boot toggle and detection via Calamares modules
- Custom Welcome App with progress logging and neon styled interface

## Repository layout

This repository contains the archiso profile as well as supporting directories used to build XanadOS.

- `xanados-iso/` – archiso profile and build scripts
- `xanados-iso/calamares/` – Calamares installer configuration
- `xanados-iso/airootfs/` – root filesystem for the live environment
- `xanados-iso/packages.x86_64` – package list for the ISO
- `xanados-iso/bootstrap_packages.x86_64` – minimal bootstrap package list
- `xanados-iso/docs/` – additional documentation
- `packages/` – custom PKGBUILDs
- `scripts/` – automation scripts
- `configs/` – configuration snippets
- `docs/` – project documentation
- `logs/` – build and test logs
- `frontend/` – Next.js based web frontend

## Building the ISO

1. Install the `archiso` package:
   ```bash
   sudo pacman -S archiso
   ```
2. Clone this repository and enter the profile directory:
   ```bash
   git clone <repository-url>
   cd xanados/xanados-iso
   ```
3. Run `mkarchiso` to create the image (output will be placed in the `out/` directory):
   ```bash
   sudo mkarchiso -v -o out .
   ```
4. Flash the resulting ISO to a USB drive:
   ```bash
   sudo dd if=out/xanados-*.iso of=/dev/sdX bs=4M status=progress && sync
   ```

## Installing XanadOS

1. Boot your machine from the USB stick.
2. On first login the **Welcome App** appears. Pick Gaming, Minimal or Recommended to install the desired packages. Logs are saved to `/tmp/welcome.log` and the autostart entry is provided by `/etc/xanados/welcome.desktop`.
3. Run the Calamares installer from the live session to install the system to disk.

For more details see [`xanados-iso/docs/README_XANADOS.md`](xanados-iso/docs/README_XANADOS.md).

## Running the Next.js frontend

The repository also contains a web-based frontend located in `frontend/`. All
commands below are executed from the repository root and use the `--prefix`
flag to target the frontend directory.

1. Install dependencies:
   ```bash
   npm install --prefix frontend
   ```
2. Start the development server:
   ```bash
   npm run dev --prefix frontend
   ```
3. Lint the codebase:
   ```bash
   npm run lint --prefix frontend
   ```
   ESLint rules are defined in `frontend/.eslintrc.json`.
4. Generate production builds:
   ```bash
   npm run build --prefix frontend
   ```
