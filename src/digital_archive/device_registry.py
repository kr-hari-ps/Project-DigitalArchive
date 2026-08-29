from __future__ import annotations

import uuid
from .db import CatalogDatabase
from .devices import DeviceProfile


class DeviceRegistry:
    """Register and reconcile device identity without device-specific code."""

    def __init__(self, db: CatalogDatabase):
        self.db = db

    def register(self, profile: DeviceProfile, execute: bool = False) -> str:
        if not profile.device_id:
            raise ValueError("device_id is required")
        if not execute:
            return "DRY_RUN"

        with self.db.connect() as con:
            row = con.execute(
                "SELECT device_uuid FROM devices WHERE device_id=?",
                (profile.device_id,),
            ).fetchone()
            device_uuid = row["device_uuid"] if row else str(uuid.uuid4())
            con.execute(
                """INSERT INTO devices(
                    device_id, device_uuid, device_name, device_type,
                    manufacturer, model, os_name, os_version, description
                ) VALUES(?,?,?,?,?,?,?,?,?)
                ON CONFLICT(device_id) DO UPDATE SET
                    device_name=excluded.device_name,
                    device_type=excluded.device_type,
                    manufacturer=excluded.manufacturer,
                    model=excluded.model,
                    os_name=excluded.os_name,
                    os_version=excluded.os_version,
                    description=excluded.description,
                    updated_at=CURRENT_TIMESTAMP""",
                (
                    profile.device_id, device_uuid, profile.device_name,
                    profile.device_type, profile.manufacturer, profile.model,
                    profile.os_name, profile.os_version, profile.description,
                ),
            )
            for ident in profile.identifiers:
                con.execute(
                    """INSERT INTO device_identifiers(
                        device_id, identifier_type, identifier_value, is_primary
                    ) VALUES(?,?,?,?)
                    ON CONFLICT(identifier_type, identifier_value) DO UPDATE SET
                        device_id=excluded.device_id,
                        is_primary=excluded.is_primary,
                        last_seen_at=CURRENT_TIMESTAMP""",
                    (
                        profile.device_id, ident.identifier_type,
                        ident.identifier_value, int(ident.is_primary),
                    ),
                )
        return device_uuid
