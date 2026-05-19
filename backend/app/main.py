from fastapi import FastAPI
from .routers import tickets, checkout
from .database import engine, Base

app = FastAPI(title="EPIC Ticket API", version="1.0")

@app.on_event("startup")
async def init_db():
    async with engine.begin() as conn:
        # Buat tabel jika belum ada
        await conn.run_sync(Base.metadata.create_all)

app.include_router(tickets.router)
app.include_router(checkout.router)

@app.get("/")
async def root():
    return {"message": "EPIC Ticket API is running with PostgreSQL"}