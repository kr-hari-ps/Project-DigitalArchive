from __future__ import annotations

import sqlite3
from pathlib import Path


class CatalogDatabase:
    """Small reusable SQLite access layer used by CLI and UI services."""

    def __init__(self, path: str | Path):
        self.path = Path(path).expanduser()

    def connect(self) -> sqlite3.Connection:
        con = sqlite3.connect(self.path)
        con.row_factory = sqlite3.Row
        con.execute("PRAGMA foreign_keys=ON")
        return con

    def device(self, device_id: str):
        with self.connect() as con:
            return con.execute(
                "SELECT * FROM devices WHERE device_id=?", (device_id,)
            ).fetchone()

    def identifiers(self, device_id: str):
        with self.connect() as con:
            return con.execute(
                "SELECT * FROM device_identifiers WHERE device_id=? "
                "ORDER BY is_primary DESC, identifier_type",
                (device_id,),
            ).fetchall()

    def devices(self):
        with self.connect() as con:
            return con.execute(
                "SELECT * FROM devices ORDER BY device_name, device_id"
            ).fetchall()
