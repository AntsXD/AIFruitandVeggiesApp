from fastapi import APIRouter
from pydantic import BaseModel

from services import cart_service

router = APIRouter(prefix="/cart", tags=["cart"])


class CartAddItem(BaseModel):
    label: str
    weight_kg: float
    unit_price: float
    total: float


@router.post("/{session_id}/add")
def add_to_cart(session_id: str, body: CartAddItem) -> dict:
    return cart_service.add_item(
        session_id,
        body.label,
        body.weight_kg,
        body.unit_price,
        body.total,
    )


@router.get("/{session_id}")
def get_cart(session_id: str) -> dict:
    return cart_service.get_cart(session_id)


@router.delete("/{session_id}")
def clear_cart(session_id: str) -> dict:
    cart_service.clear_cart(session_id)
    return {"ok": True}
