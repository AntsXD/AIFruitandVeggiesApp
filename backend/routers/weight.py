from fastapi import APIRouter
from pydantic import BaseModel

from services import weight_service

router = APIRouter(prefix="/weight", tags=["weight"])


class WeightUpdate(BaseModel):
    weight_kg: float


@router.post("/update")
def update_weight(body: WeightUpdate) -> dict:
    weight_service.update_weight(body.weight_kg)
    return {"ok": True, "weight_kg": body.weight_kg}


@router.get("/current")
def get_current_weight() -> dict:
    return {"weight_kg": weight_service.get_current_weight()}
