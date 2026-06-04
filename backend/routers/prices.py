from fastapi import APIRouter

from services import price_service

router = APIRouter(prefix="/prices", tags=["prices"])


@router.get("/{label}")
def get_price(label: str) -> dict:
    return price_service.get_price(label)
