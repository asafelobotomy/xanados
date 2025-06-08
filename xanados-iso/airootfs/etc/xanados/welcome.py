#!/usr/bin/env python3

import os
import sys
import subprocess
import glob
from datetime import datetime
from PyQt5 import QtWidgets, QtGui, QtCore


class InstallerThread(QtCore.QThread):
    progress = QtCore.pyqtSignal(str)
    finished = QtCore.pyqtSignal(bool)
    log_path = QtCore.pyqtSignal(str)

    def __init__(self, scripts):
        super().__init__()
        self.scripts = scripts
        self._is_running = True

    def run(self):
        success = True
        for entry in self.scripts:
            if isinstance(entry, (list, tuple)):
                script, *args = entry
            else:
                script, args = entry, []

            if not self._is_running:
                self.progress.emit("[INFO] Installation cancelled by user.")
                success = False
                break
            if not os.path.isfile(script):
                self.progress.emit(f"[ERROR] Script not found: {script}")
                success = False
                break
            display = " ".join([script] + args)
            self.progress.emit(f"▶ Executing: {display}")
            try:
                process = subprocess.Popen(
                    ["bash", script] + args,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    universal_newlines=True,
                )
                for line in process.stdout:
                    if not self._is_running:
                        process.terminate()
                        self.progress.emit("[INFO] Installation cancelled by user.")
                        success = False
                        break
                    line = line.strip()
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    self.progress.emit(f"[{timestamp}] {line}")
                    if "Log file:" in line:
                        self.log_path.emit(line.split("Log file:", 1)[1].strip())
                process.wait()
                if process.returncode != 0:
                    self.progress.emit(f"[ERROR] Script failed: {script}")
                    success = False
                    break
            except Exception as e:
                self.progress.emit(f"[EXCEPTION] {e}")
                success = False
                break
        self.finished.emit(success)

    def stop(self):
        self._is_running = False


class WelcomeApp(QtWidgets.QWidget):
    def mousePressEvent(self, event):
        if event.button() == QtCore.Qt.LeftButton:
            self.dragPos = event.globalPos()
            event.accept()

    def mouseMoveEvent(self, event):
        if event.buttons() == QtCore.Qt.LeftButton:
            self.move(self.pos() + event.globalPos() - self.dragPos)
            self.dragPos = event.globalPos()
            event.accept()

    def __init__(self, dry_run=False):
        super().__init__()
        self.dry_run_default = dry_run
        self.installed = os.path.exists("/etc/xanados/installed")
        self.init_ui()
        self.thread = None

    def init_ui(self):
        self.setWindowFlag(QtCore.Qt.FramelessWindowHint)
        self.setAttribute(QtCore.Qt.WA_TranslucentBackground)
        shadow = QtWidgets.QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(20)
        shadow.setXOffset(0)
        shadow.setYOffset(0)
        shadow.setColor(QtGui.QColor(0, 255, 255, 120))
        self.setGraphicsEffect(shadow)
        self.setGeometry(100, 100, 600, 450)
        self.setStyleSheet("")

        layout = QtWidgets.QVBoxLayout()

        top_bar = QtWidgets.QHBoxLayout()
        top_bar.setContentsMargins(0, 0, 0, 0)
        self.title_label = QtWidgets.QLabel("  Welcome to XanadOS")
        self.title_label.setStyleSheet("font-weight: bold;")
        self.close_button = QtWidgets.QPushButton("✕")
        self.close_button.setFixedSize(30, 30)
        self.close_button.clicked.connect(self.close)
        self.close_button.setStyleSheet(
            "QPushButton { background-color: transparent; border: none; font-size: 14pt; }"
        )
        top_bar.addWidget(self.title_label)
        top_bar.addStretch()
        top_bar.addWidget(self.close_button)
        layout.addLayout(top_bar)

        self.checkbox_gaming = QtWidgets.QCheckBox("Gaming Mode")
        self.checkbox_gaming.setToolTip("Install selected gaming packages.")
        self.checkbox_minimal = QtWidgets.QCheckBox("Minimal Mode")
        self.checkbox_minimal.setToolTip(
            "Install only the essential packages for a clean setup."
        )
        self.checkbox_recommended = QtWidgets.QCheckBox("Install All Recommended")
        self.checkbox_recommended.setToolTip("Install XanadOS full package stack.")

        layout.addWidget(self.checkbox_gaming)

        self.gaming_group = QtWidgets.QGroupBox("Gaming Packages")
        self.gaming_group.setVisible(False)
        group_layout = QtWidgets.QVBoxLayout()
        self.gaming_checks = {}
        packages = [
            ("steam", "Steam"),
            ("lutris", "Lutris"),
            ("heroic-games-launcher", "Heroic Games Launcher"),
            ("gamemode", "GameMode"),
            ("mangohud", "MangoHud"),
            ("vkbasalt", "vkBasalt"),
            ("protontricks", "Protontricks"),
        ]
        for pkg, label in packages:
            cb = QtWidgets.QCheckBox(label)
            cb.setChecked(True)
            self.gaming_checks[pkg] = cb
            group_layout.addWidget(cb)
        self.gaming_group.setLayout(group_layout)
        layout.addWidget(self.gaming_group)

        layout.addWidget(self.checkbox_minimal)
        layout.addWidget(self.checkbox_recommended)

        self.browser_options = {
            "Brave": "brave",
            "Firefox": "firefox",
            "Chromium": "chromium",
            "Vivaldi": "vivaldi",
            "Tor Browser": "torbrowser-launcher",
            "Opera": "opera",
        }
        browser_layout = QtWidgets.QHBoxLayout()
        browser_label = QtWidgets.QLabel("Web Browser:")
        self.browser_combo = QtWidgets.QComboBox()
        self.browser_combo.addItems(self.browser_options.keys())
        self.browser_combo.setCurrentText("Brave")
        browser_layout.addWidget(browser_label)
        browser_layout.addWidget(self.browser_combo)
        layout.addLayout(browser_layout)

        self.checkbox_dry_run = QtWidgets.QCheckBox("Dry Run")
        self.checkbox_dry_run.setToolTip("Show the commands without executing them.")
        self.checkbox_dry_run.setChecked(self.dry_run_default)
        layout.addWidget(self.checkbox_dry_run)

        buttons_layout = QtWidgets.QHBoxLayout()
        self.install_button = QtWidgets.QPushButton("Start Installation")
        self.install_button.setEnabled(False)
        buttons_layout.addWidget(self.install_button)

        self.cancel_button = QtWidgets.QPushButton("Cancel Installation")
        self.cancel_button.setEnabled(False)
        buttons_layout.addWidget(self.cancel_button)

        layout.addLayout(buttons_layout)

        self.progress_bar = QtWidgets.QProgressBar()
        self.progress_bar.setRange(0, 0)
        self.progress_bar.setVisible(False)
        layout.addWidget(self.progress_bar)

        self.log_output = QtWidgets.QTextEdit()
        self.log_output.setReadOnly(True)
        layout.addWidget(self.log_output)

        self.log_label = QtWidgets.QLabel("")
        layout.addWidget(self.log_label)

        self.log_file = None
        self.log_timer = QtCore.QTimer(self)
        self.log_timer.timeout.connect(self.read_log_updates)
        self.find_latest_log()

        self.setLayout(layout)

        for box in [
            self.checkbox_gaming,
            self.checkbox_minimal,
            self.checkbox_recommended,
        ]:
            box.stateChanged.connect(self.update_button_state)

        self.checkbox_gaming.stateChanged.connect(
            lambda: self.gaming_group.setVisible(self.checkbox_gaming.isChecked())
        )

        if os.path.exists("/etc/xanados/secureboot_enabled"):
            self.log_output.append("[!] Secure Boot is enabled.")

        if self.installed:
            self.log_output.append(
                "[INFO] Detected installed system. Installation options disabled."
            )
            self.checkbox_gaming.setEnabled(False)
            self.checkbox_minimal.setEnabled(False)
            self.checkbox_recommended.setEnabled(False)
            self.install_button.setText("Run Maintenance")
            self.install_button.clicked.connect(self.run_maintenance)
        else:
            self.install_button.clicked.connect(self.start_installation)

        self.cancel_button.clicked.connect(self.cancel_installation)

    def update_button_state(self):
        any_checked = any(
            box.isChecked()
            for box in [
                self.checkbox_gaming,
                self.checkbox_minimal,
                self.checkbox_recommended,
            ]
        )
        self.install_button.setEnabled(any_checked)

    def start_installation(self):
        if os.geteuid() != 0:
            QtWidgets.QMessageBox.warning(
                self,
                "Insufficient Privileges",
                "Please run this installer with root permissions.",
            )
            return
        scripts = []
        dry_flag = ["--dry-run"] if self.checkbox_dry_run.isChecked() else []
        if self.checkbox_gaming.isChecked():
            selected = [pkg for pkg, cb in self.gaming_checks.items() if cb.isChecked()]
            if selected:
                scripts.append(
                    ["/etc/xanados/scripts/install_gaming.sh", *selected, *dry_flag]
                )
            else:
                scripts.append(["/etc/xanados/scripts/install_gaming.sh", *dry_flag])
        if self.checkbox_minimal.isChecked():
            scripts.append(["/etc/xanados/scripts/install_minimal.sh", *dry_flag])
        if self.checkbox_recommended.isChecked():
            browser_pkg = self.browser_options[self.browser_combo.currentText()]
            scripts.append(
                [
                    "/etc/xanados/scripts/install_recommended.sh",
                    "--browser",
                    browser_pkg,
                    *dry_flag,
                ]
            )

        self.thread = InstallerThread(scripts)
        self.thread.progress.connect(
            lambda msg: (
                self.log_output.append(msg),
                self.log_output.ensureCursorVisible(),
            )
        )
        self.thread.log_path.connect(self.set_log_file)
        self.thread.finished.connect(self.install_finished)
        self.progress_bar.setVisible(True)
        self.install_button.setEnabled(False)
        self.cancel_button.setEnabled(True)
        self.checkbox_gaming.setEnabled(False)
        self.checkbox_minimal.setEnabled(False)
        self.checkbox_recommended.setEnabled(False)
        self.checkbox_dry_run.setEnabled(False)
        self.thread.start()

    def run_maintenance(self):
        if os.geteuid() != 0:
            self.log_output.append("[ERROR] Maintenance requires root privileges.")
            return
        self.log_output.append("[INFO] Running post-install maintenance tasks...")
        commands = [
            "paru -Syu --noconfirm",
            "paccache -r",
            "systemctl status NetworkManager",
            "systemctl status chronyd",
            "journalctl -b -1 --no-pager | tail -n 50",
            "lsblk -f",
        ]
        for cmd in commands:
            self.log_output.append(f"▶ {cmd}")
            try:
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                output = result.stdout.strip() or "[no output]"
                self.log_output.append(output)
            except Exception as e:
                self.log_output.append(f"[ERROR] Failed to run {cmd}: {e}")

    def cancel_installation(self):
        if self.thread and self.thread.isRunning():
            self.thread.stop()
            self.cancel_button.setEnabled(False)

    def install_finished(self, success):
        self.progress_bar.setVisible(False)
        self.cancel_button.setEnabled(False)
        if success:
            QtWidgets.QMessageBox.information(
                self, "Installation Complete", "Installation completed successfully!"
            )
        else:
            QtWidgets.QMessageBox.warning(
                self,
                "Installation Error",
                "Installation was interrupted or failed. Check logs for details.",
            )
        self.install_button.setEnabled(True)
        self.checkbox_gaming.setEnabled(True)
        self.checkbox_minimal.setEnabled(True)
        self.checkbox_recommended.setEnabled(True)
        self.checkbox_dry_run.setEnabled(True)

    def find_latest_log(self):
        logs = glob.glob("/tmp/welcome_install_*.log")
        if logs:
            latest = max(logs, key=os.path.getmtime)
            self.set_log_file(latest)
        else:
            self.log_label.setText("Log file: none found")

    def set_log_file(self, path):
        if getattr(self, "log_file", None):
            try:
                self.log_file.close()
            except Exception:
                pass
        self.log_file_path = path
        try:
            self.log_file = open(path, "r")
            self.log_label.setText(f"Log file: {path}")
        except Exception as e:
            self.log_output.append(f"[ERROR] Unable to open log {path}: {e}")
            self.log_label.setText(f"Log file: {path} (error)")
            self.log_file = None
            return
        self.log_timer.start(1000)

    def read_log_updates(self):
        if not getattr(self, "log_file", None):
            return
        for line in self.log_file.readlines():
            self.log_output.append(line.rstrip())
            self.log_output.ensureCursorVisible()


if __name__ == "__main__":
    dry_cli = False
    if "--dry-run" in sys.argv:
        dry_cli = True
        sys.argv.remove("--dry-run")
    app = QtWidgets.QApplication(sys.argv)
    win = WelcomeApp(dry_run=dry_cli)
    win.show()
    sys.exit(app.exec_())
