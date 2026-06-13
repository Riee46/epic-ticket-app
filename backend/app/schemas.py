from pydantic import BaseModel, EmailStr, ConfigDict
from datetime import datetime
from typing import Optional

# Untuk response GET /tickets
class TicketResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
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

# --- User schemas ---
class LoginRequest(BaseModel):
    username: str
    password: str

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    username: str
    email: str
    is_admin: bool
    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str
    
class TransactionOut(BaseModel):
    id: int
    transaction_id: str
    user_id: int
    ticket_id: int
    quantity: int
    total_price: int
    status: str
    payment_proof_url: Optional[str] = None
    timestamp: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

class VerifyPayment(BaseModel):
    transaction_id: int
    action: str

class ScanQRRequest(BaseModel):
    ticket_code: str

class TicketQRResponse(BaseModel):
    id: int
    ticket_code: str
    used: bool
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)