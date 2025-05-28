#!/usr/bin/env python3

import os
import sys
import subprocess
from PyQt5 import QtWidgets, QtGui, QtCore

class InstallerThread(QtCore.QThread):
    progress = QtCore.pyqtSignal(str)

    def __init__(self, scripts):
        super().__init__()
        self.scripts = scripts

    def run(self):
        for script in self.scripts:
            if not os.path.isfile(script):
                self.progress.emit(f"[ERROR] Script not found: {script}")
                continue
            self.progress.emit(f"▶ Executing: {script}")
            try:
                process = subprocess.Popen(
                    ['bash', script],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    universal_newlines=True
                )
                for line in process.stdout:
                    self.progress.emit(line.strip())
                process.wait()
                if process.returncode != 0:
                    self.progress.emit(f"[ERROR] Script failed: {script}")
            except Exception as e:
                self.progress.emit(f"[EXCEPTION] {e}")
        self.progress.emit("✔ All selected tasks complete. Check /tmp/welcome.log if needed.")

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
        self.init_ui()

    def init_ui(self):
        self.setWindowFlag(QtCore.Qt.FramelessWindowHint)
        self.setAttribute(QtCore.Qt.WA_TranslucentBackground)
        shadow = QtWidgets.QGraphicsDropShadowEffect(self)
        shadow.setBlurRadius(20)
        shadow.setXOffset(0)
        shadow.setYOffset(0)
        shadow.setColor(QtGui.QColor(0, 255, 255, 120))
        self.setGraphicsEffect(shadow)
        self.setGeometry(100, 100, 600, 400)
        self.setStyleSheet("""
            QWidget {
                background-color: #0D0D0D;
                color: #FF00FF;
                font-family: 'JetBrains Mono';
                font-size: 12pt;
            }
            QCheckBox {
                margin: 10px;
            }
            QPushButton {
                background-color: #111111;
                color: #00FFFF;
                border: 2px solid #FF00FF;
                border-radius: 6px;
                padding: 8px;
            }
            QPushButton:disabled {
                color: gray;
                border-color: gray;
            }
            QTextEdit {
                background-color: #1A1A1A;
                border: 1px solid #FF00FF;
                padding: 6px;
                color: #00FFFF;
            }
        """)

        layout = QtWidgets.QVBoxLayout()

        top_bar = QtWidgets.QHBoxLayout()
        top_bar.setContentsMargins(0, 0, 0, 0)
        self.title_label = QtWidgets.QLabel("  Welcome to XanadOS")
        self.title_label.setStyleSheet('font-weight: bold; color: #00FFFF;')
        self.close_button = QtWidgets.QPushButton("✕")
        self.close_button.setFixedSize(30, 30)
        self.close_button.clicked.connect(self.close)
        self.close_button.setStyleSheet('QPushButton { background-color: transparent; color: #FF00FF; border: none; font-size: 14pt; } QPushButton:hover { color: red; }')
        top_bar.addWidget(self.title_label)
        top_bar.addStretch()
        top_bar.addWidget(self.close_button)
        layout.addLayout(top_bar)

        self.checkbox_gaming = QtWidgets.QCheckBox("Gaming Mode")
        self.checkbox_gaming.setToolTip("Install Steam, Lutris, Heroic, vkBasalt, MangoHud, etc.")
        self.checkbox_minimal = QtWidgets.QCheckBox("Minimal Mode")
        self.checkbox_minimal.setToolTip("Install only the essential packages for a clean setup.")
        self.checkbox_recommended = QtWidgets.QCheckBox("Install All Recommended")
        self.checkbox_recommended.setToolTip("Install XanadOS full package stack.")

        layout.addWidget(self.checkbox_gaming)
        layout.addWidget(self.checkbox_minimal)
        layout.addWidget(self.checkbox_recommended)

        self.install_button = QtWidgets.QPushButton("Start Installation")
        self.install_button.setEnabled(False)
        self.install_button.clicked.connect(self.start_installation)

        layout.addWidget(self.install_button)
        self.progress_bar = QtWidgets.QProgressBar()
        self.progress_bar.setRange(0, 0)
        self.progress_bar.setVisible(False)
        layout.addWidget(self.progress_bar)

        self.log_output = QtWidgets.QTextEdit()
        self.log_output.setReadOnly(True)
        layout.addWidget(self.log_output)

        self.setLayout(layout)

        for box in [self.checkbox_gaming, self.checkbox_minimal, self.checkbox_recommended]:
            box.stateChanged.connect(self.update_button_state)

        if os.path.exists("/etc/xanados/secureboot_enabled"):
            self.log_output.append("[!] Secure Boot is enabled.")

    def update_button_state(self):
        any_checked = any(box.isChecked() for box in [
            self.checkbox_gaming, self.checkbox_minimal, self.checkbox_recommended
        ])
        self.install_button.setEnabled(any_checked)

    def start_installation(self):
        scripts = []
        if self.checkbox_gaming.isChecked(): scripts.append('/etc/xanados/scripts/install_gaming.sh')
        if self.checkbox_minimal.isChecked(): scripts.append('/etc/xanados/scripts/install_minimal.sh')
        if self.checkbox_recommended.isChecked(): scripts.append('/etc/xanados/scripts/install_recommended.sh')

        self.thread = InstallerThread(scripts)
        self.thread.progress.connect(lambda msg: (self.log_output.append(msg), self.log_output.ensureCursorVisible()))
        self.progress_bar.setVisible(True)
        self.install_button.setEnabled(False)
        self.checkbox_gaming.setEnabled(False)
        self.checkbox_minimal.setEnabled(False)
        self.checkbox_recommended.setEnabled(False)
        self.thread.start()

if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    win = WelcomeApp()
    win.show()
    sys.exit(app.exec_())
