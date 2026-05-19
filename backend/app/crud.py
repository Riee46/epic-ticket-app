from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from .models import Ticket, Transaction
import uuid

async def get_all_tickets(db: AsyncSession):
    result = await db.execute(select(Ticket))
    return result.scalars().all()

async def get_ticket_by_id(db: AsyncSession, ticket_id: int):
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id))
    return result.scalar_one_or_none()

async def update_ticket_quota(db: AsyncSession, ticket_id: int, quantity: int):
    ticket = await get_ticket_by_id(db, ticket_id)
    if ticket and ticket.quota >= quantity:
        ticket.quota -= quantity
        db.add(ticket)
        await db.commit()
        await db.refresh(ticket)
        return True
    return False

async def create_transaction(db: AsyncSession, ticket_id: int, quantity: int, total_price: int):
    trans_id = f"TRX-{uuid.uuid4().hex[:8].upper()}"
    transaction = Transaction(
        transaction_id=trans_id,
        ticket_id=ticket_id,
        quantity=quantity,
        total_price=total_price
    )
    db.add(transaction)
    await db.commit()
    await db.refresh(transaction)
    return trans_id