from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..crud import get_ticket_by_id, update_ticket_quota, create_transaction
from ..schemas import CheckoutRequest
from ..dependencies import get_current_user
import uuid

router = APIRouter()

@router.post("/checkout")
async def checkout(
    request: CheckoutRequest,
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ticket = await get_ticket_by_id(db, request.ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail={"status": "failed", "message": "Tiket tidak ditemukan"})
    if ticket.quota < request.quantity:
        raise HTTPException(status_code=400, detail={"status": "failed", "message": f"Kuota tidak mencukupi. Sisa: {ticket.quota}"})
    
    updated = await update_ticket_quota(db, request.ticket_id, request.quantity)
    if not updated:
        raise HTTPException(status_code=400, detail={"status": "failed", "message": "Gagal update kuota"})
    
    total_price = ticket.price * request.quantity
    trans_id = f"TRX-{uuid.uuid4().hex[:8].upper()}"
    # Simpan transaksi dengan status pending
    await create_transaction(
    db,
    current_user.id,
    request.ticket_id,
    request.quantity,
    total_price,
    trans_id,
    status="pending"  # ini sudah benar
)
    
    return {
        "status": "success",
        "message": "Checkout berhasil, menunggu verifikasi pembayaran",
        "data": {
            "id_transaksi": trans_id,
            "total_price": total_price,
            "ticket_id": request.ticket_id,
            "quantity": request.quantity
        }
    }