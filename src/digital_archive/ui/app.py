from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtWidgets import (
    QApplication, QComboBox, QLabel, QMainWindow, QMessageBox,
    QPushButton, QVBoxLayout, QWidget,
)

from ..db import CatalogDatabase
from ..device_registry import DeviceRegistry
from ..devices import discover_host_profile

DEFAULT_DB = Path.home() / "Master-Repository/.archive/catalog.db"


class MainWindow(QMainWindow):
    def __init__(self, db_path: Path = DEFAULT_DB):
        super().__init__()
        self.db = CatalogDatabase(db_path)
        self.registry = DeviceRegistry(self.db)
        self.setWindowTitle("Digital Archive")
        self.resize(620, 420)

        layout = QVBoxLayout()
        layout.addWidget(QLabel("Device Management"))
        self.devices = QComboBox()
        self.refresh_devices()
        layout.addWidget(self.devices)

        connect = QPushButton("Connect / Detect Device")
        connect.clicked.connect(self.detect_device)
        layout.addWidget(connect)

        register = QPushButton("Register / Reconcile Device")
        register.clicked.connect(self.register_device)
        layout.addWidget(register)

        layout.addWidget(QLabel("Other operations will be added as separate workflows."))
        root = QWidget()
        root.setLayout(layout)
        self.setCentralWidget(root)

    def refresh_devices(self):
        self.devices.clear()
        for row in self.db.devices():
            self.devices.addItem(
                f"{row['device_id']} — {row['device_name']}", row['device_id']
            )

    def detect_device(self):
        device_id = self.devices.currentData()
        if not device_id:
            QMessageBox.information(self, "Device", "Select a registered device first.")
            return
        profile = discover_host_profile(device_id)
        details = [
            f"Device ID: {profile.device_id}",
            f"Name: {profile.device_name}",
            f"Type: {profile.device_type}",
            f"OS: {profile.os_name} {profile.os_version or ''}".strip(),
        ]
        QMessageBox.information(self, "Detected Device", "\n".join(details))

    def register_device(self):
        device_id = self.devices.currentData()
        if not device_id:
            QMessageBox.information(self, "Device", "Select a registered device first.")
            return
        profile = discover_host_profile(device_id)
        self.registry.register(profile, execute=True)
        self.refresh_devices()
        QMessageBox.information(self, "Device", "Device identity reconciled successfully.")


def main() -> int:
    if os.environ.get("QT_QPA_PLATFORM") is None and not os.environ.get("DISPLAY"):
        os.environ["QT_QPA_PLATFORM"] = "offscreen"
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    return app.exec()
