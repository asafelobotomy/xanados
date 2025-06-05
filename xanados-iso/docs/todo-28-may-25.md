✅ XanadOS Finalization Checklist – Pre-Deployment
🔧 1. Theming & Visuals
🎨 SDDM Login Screen
Design and render custom SDDM theme (match GRUB & Plymouth style)

Configure sddm.conf to use new theme

Test login resolution and scaling

🖼️ Desktop Branding
Set default wallpaper, icons, fonts

Apply global theme via plasma-org.kde.plasma.desktop-appletsrc

Configure KDE to disable compositor in fullscreen

Configure splash screen and lock screen branding

🧠 2. Welcome App – Final Build
Complete PyQt5 UI build with checkboxes, tooltips, sectioning

Implement install scripts behind each checkbox (Flatpak, Paru, custom)

Wire presets: Gaming Mode, Minimal Mode, Install All Recommended

Add Secure Boot state check (/etc/xanados/secureboot_enabled)

Add progress bar/logging during installs

Auto-disable post-first-run

Desktop launcher + system menu entry

🛠️ 3. Calamares Installer
Finalize Calamares settings.conf + modules.conf

Confirm secure boot module logic (when toggle selected)

Test full install with:

Encrypted disk

UEFI + Secure Boot

Legacy BIOS

Timeshift/Btrfs enabled

Update branding (logo, styling, colors)

📁 4. File Structure & System Configs
Finalize /etc/skel with preconfigured desktop, bashrc/zshrc

Clean up /etc/xanados/ directory for flags, scripts

Apply udev rules for internal drive automount

Configure systemd services:

preload, earlyoom, nohang

Confirm fstab automount logic during install (Calamares post-hook)

💿 5. Build System / ISO Tooling
Complete archiso config and build scripts

Validate packages.x86_64 and bootstrap_packages.x86_64

Embed custom GRUB theme and Plymouth assets

Finalize mkinitcpio with optional microcode + zram

Build ISO with mkarchiso

Test ISO in:

QEMU/KVM

VirtualBox

Real hardware (UEFI + Legacy BIOS)

🧪 6. Testing & QA
First boot test

Welcome App logic test

Full install test w/ default + custom options

Test optional apps install (gaming, security, appearance)

Flatpak integration check (Discover, permissions)

System resource test (idle RAM, CPU usage)

Secure Boot test

Steam/Proton game test (Lutris + Heroic too)

🚀 7. Final Touches
Add release notes

Add known issues

Write GitHub README + install guide

Optional: prepare calamares.yaml for reproducible builds

Create changelog for v1.0

🌐 8. Release & Deployment
Upload ISO to GitHub / GitLab / hosting

Provide .sig and checksum

Submit to DistroWatch or similar (optional)

Consider creating a XanadOS website or landing page

📌 You Are Currently Here:
✅ ISO structure uploaded
✅ Most configs outlined
🔜 Final work is primarily in:

SDDM design

Welcome App scripting

Installer logic

System testing & polish
