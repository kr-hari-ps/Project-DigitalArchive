from __future__ import annotations

from dataclasses import dataclass, field
import platform
import socket
import uuid


@dataclass(frozen=True)
class DeviceIdentifier:
    identifier_type: str
    identifier_value: str
    is_primary: bool = False


@dataclass
class DeviceProfile:
    device_id: str
    device_name: str
    device_type: str
    manufacturer: str | None = None
    model: str | None = None
    os_name: str | None = None
    os_version: str | None = None
    description: str | None = None
    identifiers: list[DeviceIdentifier] = field(default_factory=list)


def discover_host_profile(device_id: str) -> DeviceProfile:
    """Discover safe host-level identity data.

    Device-specific adapters can add stronger identifiers later; this function
    deliberately does not assume Android, Windows, Linux, or any one platform.
    """
    system = platform.system() or None
    release = platform.release() or None
    hostname = socket.gethostname() or None
    identifiers: list[DeviceIdentifier] = []
    if hostname:
        identifiers.append(DeviceIdentifier("HOSTNAME", hostname, True))
    identifiers.append(DeviceIdentifier("HOST_UUID", str(uuid.getnode()), False))

    return DeviceProfile(
        device_id=device_id,
        device_name=hostname or device_id,
        device_type="HOST",
        os_name=system,
        os_version=release,
        description="Auto-discovered host/device profile",
        identifiers=identifiers,
    )
