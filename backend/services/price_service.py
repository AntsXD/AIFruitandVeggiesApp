"""Stub per-kg prices keyed by simplified fruit/vegetable label."""

# Default price for labels not explicitly listed
_DEFAULT_PRICE = 2.99

_PRICES_PER_KG: dict[str, float] = {
    "Apple": 3.49,
    "Banana": 1.99,
    "Cucumber": 1.99,
    "Orange": 2.99,
    "Potato": 1.29,
    "Tomato": 2.49,
}


def get_price(label: str) -> dict:
    price = _PRICES_PER_KG.get(label, _DEFAULT_PRICE)
    return {"label": label, "price_per_kg": price}
