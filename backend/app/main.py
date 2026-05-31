from fastapi import FastAPI
from .routers import tickets, checkout, auth, admin, user
from .database import engine, Base

app = FastAPI(title="EPIC Ticket API", version="1.0")

@app.on_event("startup")
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app.include_router(auth.router)
app.include_router(tickets.router)
app.include_router(checkout.router)
app.include_router(admin.router)
app.include_router(user.router)

@app.get("/")
async def root():
    return {"message": "EPIC Ticket API is running with PostgreSQL"}