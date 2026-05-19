from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..crud import get_all_tickets
from ..schemas import TicketResponse

router = APIRouter()

@router.get("/tickets")
async def get_tickets(db: AsyncSession = Depends(get_db)):
    tickets = await get_all_tickets(db)
    return {
        "status": "success",
        "data": [TicketResponse.model_validate(t).model_dump() for t in tickets]
    }