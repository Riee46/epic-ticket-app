from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

# Untuk response GET /tickets
class TicketResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # ← tambahkan ini
    id: int
    category: str
    price: int
    quota: int

# Request POST /checkout
class CheckoutRequest(BaseModel):
    ticket_id: int
    quantity: int

# Data transaksi dalam response sukses
class TransactionData(BaseModel):
    id_transaksi: str
    total_price: int
    ticket_id: Optional[int] = None
    quantity: Optional[int] = None

# Response sukses umum
class SuccessResponse(BaseModel):
    status: str
    message: str
    data: TransactionData

# Response error
class ErrorDetail(BaseModel):
    status: str
    message: str