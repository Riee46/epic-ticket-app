from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..crud import get_all_pending_transactions, get_transaction_by_id, update_transaction_status, create_ticket_qr, get_admin_stats, get_all_paid_transactions, update_ticket_price
from ..schemas import TransactionOut, VerifyPayment, TicketQRResponse, ScanQRRequest, TicketUpdate
from ..dependencies import get_current_admin
import uuid

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/transactions/pending", response_model=list[TransactionOut])
async def get_pending_transactions(
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    transactions = await get_all_pending_transactions(db)
    return transactions

@router.get("/transactions/paid", response_model=list[TransactionOut])
async def get_paid_transactions(
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    transactions = await get_all_paid_transactions(db)
    return transactions

@router.get("/stats")
async def get_stats(
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await get_admin_stats(db)

@router.post("/verify-payment")
async def verify_payment(
    verify: VerifyPayment,
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    transaction = await get_transaction_by_id(db, verify.transaction_id)
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    if verify.action == "approve":
        await update_transaction_status(db, verify.transaction_id, "paid")
        ticket_code = f"QR-{uuid.uuid4().hex[:12].upper()}"
        await create_ticket_qr(db, transaction.user_id, ticket_code, transaction.id)
        return {"status": "success", "message": "Payment approved, QR generated", "ticket_code": ticket_code}
    elif verify.action == "reject":
        await update_transaction_status(db, verify.transaction_id, "rejected")
        return {"status": "success", "message": "Payment rejected"}
    else:
        raise HTTPException(status_code=400, detail="Invalid action")

@router.post("/scan", response_model=TicketQRResponse)
async def scan_qr(
    scan_data: ScanQRRequest,
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    from ..crud import get_ticket_qr_by_code, mark_qr_used
    qr = await get_ticket_qr_by_code(db, scan_data.ticket_code)
    if not qr:
        raise HTTPException(status_code=404, detail="QR code not found")
    if qr.used:
        raise HTTPException(status_code=400, detail="Ticket already used")
    await mark_qr_used(db, qr.id)
    return qr

@router.put("/tickets/{ticket_id}")
async def update_ticket(
    ticket_id: int,
    ticket_update: TicketUpdate,
    current_admin = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    updated_ticket = await update_ticket_price(db, ticket_id, ticket_update.price)
    if not updated_ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return {"status": "success", "message": "Ticket price updated", "ticket": {"id": updated_ticket.id, "price": updated_ticket.price}}