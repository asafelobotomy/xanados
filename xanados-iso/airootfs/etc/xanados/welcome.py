#!/usr/bin/env python3

import os
import sys
import subprocess
from datetime import datetime
from PyQt5 import QtWidgets, QtGui, QtCore


class InstallerThread(QtCore.QThread):
    progress = QtCore.pyqtSignal(str)
    finished = QtCore.pyqtSignal(bool)

    def __init__(self, scripts):
        super().__init__()
        self.scripts = scripts
        self._is_running = True

    def run(self):
        success = True
        for script in self.scripts:
            if not self._is_running:
                self.progress.emit("[INFO] Installation cancelled by user.")
                success = False
                break
            if not os.path.isfile(script):
                self.progress.emit(f"[ERROR] Script not found: {script}")
                success = False
                break
            self.progress.emit(f"▶ Executing: {script}")
            try:
                process = subprocess.Popen(
                    ["bash", script],
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
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    self.progress.emit(f"[{timestamp}] {line.strip()}")
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

    def __init__(self):
        super().__init__()
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
        self.checkbox_gaming.setToolTip(
            "Install Steam, Lutris, Heroic, vkBasalt, MangoHud, etc."
        )
        self.checkbox_minimal = QtWidgets.QCheckBox("Minimal Mode")
        self.checkbox_minimal.setToolTip(
            "Install only the essential packages for a clean setup."
        )
        self.checkbox_recommended = QtWidgets.QCheckBox("Install All Recommended")
        self.checkbox_recommended.setToolTip("Install XanadOS full package stack.")

        layout.addWidget(self.checkbox_gaming)
        layout.addWidget(self.checkbox_minimal)
        layout.addWidget(self.checkbox_recommended)

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

        self.setLayout(layout)

        for box in [
            self.checkbox_gaming,
            self.checkbox_minimal,
            self.checkbox_recommended,
        ]:
            box.stateChanged.connect(self.update_button_state)

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
        if self.checkbox_gaming.isChecked():
            scripts.append("/etc/xanados/scripts/install_gaming.sh")
        if self.checkbox_minimal.isChecked():
            scripts.append("/etc/xanados/scripts/install_minimal.sh")
        if self.checkbox_recommended.isChecked():
            scripts.append("/etc/xanados/scripts/install_recommended.sh")

        self.thread = InstallerThread(scripts)
        self.thread.progress.connect(
            lambda msg: (
                self.log_output.append(msg),
                self.log_output.ensureCursorVisible(),
            )
        )
        self.thread.finished.connect(self.install_finished)
        self.progress_bar.setVisible(True)
        self.install_button.setEnabled(False)
        self.cancel_button.setEnabled(True)
        self.checkbox_gaming.setEnabled(False)
        self.checkbox_minimal.setEnabled(False)
        self.checkbox_recommended.setEnabled(False)
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


if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    win = WelcomeApp()
    win.show()
    sys.exit(app.exec_())
