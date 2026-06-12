from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..models import User  # <-- IMPORT INI
from ..dependencies import get_current_user
from ..schemas import TicketQRResponse
from sqlalchemy import select

router = APIRouter(prefix="/user", tags=["user"])

@router.get("/tickets/qr", response_model=list[TicketQRResponse])
async def get_my_qr_codes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from ..models import TicketQR
    result = await db.execute(
        select(TicketQR).where(TicketQR.user_id == current_user.id)
    )
    qr_codes = result.scalars().all()
    return qr_codes

# Endpoint untuk mendapatkan info user saat ini (opsional)
@router.get("/me")
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "is_admin": current_user.is_admin
    }