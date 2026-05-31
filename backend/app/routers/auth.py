from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..schemas import UserCreate, UserOut, Token
from ..crud import get_user_by_username, get_user_by_email, create_user
from ..auth import get_password_hash, verify_password, create_access_token
from pydantic import BaseModel

router = APIRouter()

@router.post("/register", response_model=UserOut)
async def register(user: UserCreate, db: AsyncSession = Depends(get_db)):
    existing_user = await get_user_by_username(db, user.username)
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    existing_email = await get_user_by_email(db, user.email)
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed = get_password_hash(user.password)
    user_dict = user.model_dump()   # ← ubah dari .dict() ke .model_dump()
    user_dict.pop("password")
    user_dict["hashed_password"] = hashed
    new_user = await create_user(db, user_dict)
    return new_user

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login-json", response_model=Token)
async def login_json(login_data: LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_username(db, login_data.username)
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}