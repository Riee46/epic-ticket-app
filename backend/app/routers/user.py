from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..database import get_db
from ..models import TicketQR
from ..schemas import TicketQRResponse
from ..dependencies import get_current_user

router = APIRouter(prefix="/user", tags=["user"])

@router.get("/tickets/qr", response_model=list[TicketQRResponse])
async def get_my_qr_codes(
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(TicketQR).where(TicketQR.user_id == current_user.id)
    )
    qr_codes = result.scalars().all()
    return qr_codes