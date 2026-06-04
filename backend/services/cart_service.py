"""In-memory cart sessions keyed by session_id."""

from typing import Any

_carts: dict[str, dict[str, Any]] = {}


def _ensure_session(session_id: str) -> dict[str, Any]:
    if session_id not in _carts:
        _carts[session_id] = {"items": [], "subtotal": 0.0}
    return _carts[session_id]


def add_item(
    session_id: str,
    label: str,
    weight_kg: float,
    unit_price: float,
    total: float,
) -> dict[str, Any]:
    cart = _ensure_session(session_id)
    item = {
        "label": label,
        "weight_kg": weight_kg,
        "unit_price": unit_price,
        "total": total,
    }
    cart["items"].append(item)
    cart["subtotal"] = round(
        sum(i["total"] for i in cart["items"]),
        2,
    )
    return cart


def get_cart(session_id: str) -> dict[str, Any]:
    return _ensure_session(session_id)


def clear_cart(session_id: str) -> None:
    _carts[session_id] = {"items": [], "subtotal": 0.0}
