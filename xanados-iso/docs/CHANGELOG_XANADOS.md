# XanadOS ISO v2 – Changelog

## [v2] - 280525

### Added
- Modular PyQt5 Welcome App with checkbox-based mode selection
- Gaming, Minimal, and Recommended install modes with script execution
- Real-time logging to GUI and /tmp/welcome.log
- Autostart via XDG for first login
- Secure Boot detection with GUI notice
- Frameless UI with drop shadow and glow effects
- Progress bar and UI disabling during install

### Fixed
- Cleaned broken symlinks from v1
- Removed cloud-init and cloud-* service junk
- Cleaned up mkinitcpio and pacman configs

### Missing (Now Fixed)
- Added `welcome.desktop` autostart entry
- Fixed malformed logging and duplicated threads in `welcome.py`
