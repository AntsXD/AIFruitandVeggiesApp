from typing import Any

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

from services import receipt_service

router = APIRouter(prefix="/receipt", tags=["receipt"])


class ReceiptGenerateRequest(BaseModel):
    cart: dict[str, Any]
    base_url: str | None = None


@router.post("/generate")
def generate_receipt(body: ReceiptGenerateRequest, request: Request) -> dict:
    base = body.base_url or str(request.base_url).rstrip("/")
    return receipt_service.generate_receipt(body.cart, base)


@router.get("/{token}")
def get_receipt(token: str) -> dict:
    receipt = receipt_service.get_receipt(token)
    if receipt is None:
        raise HTTPException(status_code=404, detail="Receipt not found")
    return receipt
