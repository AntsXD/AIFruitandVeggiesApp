"""In-memory latest weight reading from ESP32 pushes."""

_latest_weight_kg: float = 0.0


def update_weight(weight_kg: float) -> None:
    global _latest_weight_kg
    _latest_weight_kg = weight_kg


def get_current_weight() -> float:
    return _latest_weight_kg
