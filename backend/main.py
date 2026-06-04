from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import cart, prices, receipt, weight

app = FastAPI(title="Fruit Classifier Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(weight.router)
app.include_router(prices.router)
app.include_router(cart.router)
app.include_router(receipt.router)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
