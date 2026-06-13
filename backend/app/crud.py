from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from .models import Ticket, Transaction, User, TicketQR
from sqlalchemy import update, func
import uuid

# --- Ticket CRUD ---
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

async def create_transaction(
    db: AsyncSession,
    user_id: int,
    ticket_id: int,
    quantity: int,
    total_price: int,
    transaction_id: str,
    status: str = "pending",
    payment_proof_url: str = None
):
    transaction = Transaction(
        transaction_id=transaction_id,
        user_id=user_id,
        ticket_id=ticket_id,
        quantity=quantity,
        total_price=total_price,
        status=status,
        payment_proof_url=payment_proof_url
    )
    db.add(transaction)
    await db.commit()
    await db.refresh(transaction)
    return transaction

# --- User CRUD ---
async def get_user_by_username(db: AsyncSession, username: str):
    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()

async def get_user_by_email(db: AsyncSession, email: str):
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()

async def create_user(db: AsyncSession, user_data: dict):
    db_user = User(**user_data)
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

async def get_pending_transactions(db: AsyncSession):
    result = await db.execute(select(Transaction).where(Transaction.status == 'pending'))
    return result.scalars().all()

async def get_transaction_by_id(db: AsyncSession, transaction_id: str):
    result = await db.execute(select(Transaction).where(Transaction.transaction_id == transaction_id))
    return result.scalar_one_or_none()

async def update_transaction_status(db: AsyncSession, transaction_id: str, status: str):
    stmt = update(Transaction).where(Transaction.transaction_id == transaction_id).values(status=status)
    await db.execute(stmt)
    await db.commit()

async def create_ticket_qr(db: AsyncSession, user_id: int, transaction_id: str, qr_code: str):
    qr = TicketQR(
        transaction_id=transaction_id,
        user_id=user_id,
        qr_code=qr_code,
        used=False
    )
    db.add(qr)
    await db.commit()
    await db.refresh(qr)
    return qr

async def get_qr_by_code(db: AsyncSession, qr_code: str):
    result = await db.execute(select(TicketQR).where(TicketQR.qr_code == qr_code))
    return result.scalar_one_or_none()

async def mark_qr_used(db: AsyncSession, qr_code: str):
    stmt = update(TicketQR).where(TicketQR.qr_code == qr_code).values(used=True, used_at=func.now())
    await db.execute(stmt)
    await db.commit()
    
async def get_all_pending_transactions(db: AsyncSession):
    result = await db.execute(
        select(Transaction).where(Transaction.status == "pending")
    )
    return result.scalars().all()

async def get_transaction_by_id(db: AsyncSession, transaction_id: int):
    result = await db.execute(
        select(Transaction).where(Transaction.id == transaction_id)
    )
    return result.scalar_one_or_none()

async def update_transaction_status(db: AsyncSession, transaction_id: int, status: str):
    await db.execute(
        update(Transaction)
        .where(Transaction.id == transaction_id)
        .values(status=status)
    )
    await db.commit()

# ========== QR CRUD ==========
async def create_ticket_qr(db: AsyncSession, user_id: int, ticket_code: str, transaction_id: int):
    qr = TicketQR(
        user_id=user_id,
        ticket_code=ticket_code,
        transaction_id=transaction_id,
        used=False
    )
    db.add(qr)
    await db.commit()
    await db.refresh(qr)
    return qr

async def get_ticket_qr_by_code(db: AsyncSession, ticket_code: str):
    result = await db.execute(
        select(TicketQR).where(TicketQR.ticket_code == ticket_code)
    )
    return result.scalar_one_or_none()

async def mark_qr_used(db: AsyncSession, qr_id: int):
    await db.execute(
        update(TicketQR)
        .where(TicketQR.id == qr_id)
        .values(used=True, used_at=func.now())
    )
    await db.commit()

# ========== Admin Stats ==========
async def get_admin_stats(db: AsyncSession):
    revenue_result = await db.execute(
        select(func.sum(Transaction.total_price)).where(Transaction.status == 'paid')
    )
    total_revenue = revenue_result.scalar() or 0

    tickets_result = await db.execute(
        select(func.sum(Transaction.quantity)).where(Transaction.status == 'paid')
    )
    tickets_sold = tickets_result.scalar() or 0

    pending_result = await db.execute(
        select(func.count(Transaction.id)).where(Transaction.status == 'pending')
    )
    pending_approval = pending_result.scalar() or 0

    return {
        "total_revenue": total_revenue,
        "tickets_sold": tickets_sold,
        "pending_approval": pending_approval
    }