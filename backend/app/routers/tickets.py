from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..crud import get_all_tickets
from ..schemas import TicketResponse
from ..dependencies import get_current_user

router = APIRouter()

@router.get("/tickets")
async def get_tickets(current_user = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    tickets = await get_all_tickets(db)
    return {
        "status": "success",
        "data": [TicketResponse.model_validate(t).model_dump() for t in tickets]
    } 