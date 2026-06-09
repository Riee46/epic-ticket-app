from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import tickets, checkout, auth, admin, user
from .database import engine, Base

app = FastAPI(title="EPIC Ticket API", version="1.0")

# Konfigurasi CORS - izinkan semua origin (untuk development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://epic-ticket-app-production.up.railway.app"],  # Di production, ganti dengan domain frontend Anda (misal "https://epic-ticket.web.app")
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Daftarkan router
app.include_router(auth.router)
app.include_router(tickets.router)
app.include_router(checkout.router)
app.include_router(admin.router)
app.include_router(user.router)

@app.get("/")
async def root():
    return {"message": "EPIC Ticket API is running"}