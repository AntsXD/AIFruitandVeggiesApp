"""UUID-keyed receipt store."""

import uuid
from typing import Any

_receipts: dict[str, dict[str, Any]] = {}


def generate_receipt(cart: dict[str, Any], base_url: str) -> dict[str, str]:
    token = str(uuid.uuid4())
    _receipts[token] = {
        "token": token,
        "items": cart.get("items", []),
        "subtotal": cart.get("subtotal", 0.0),
    }
    url = f"{base_url.rstrip('/')}/receipt/{token}"
    return {"token": token, "url": url}


def get_receipt(token: str) -> dict[str, Any] | None:
    return _receipts.get(token)
