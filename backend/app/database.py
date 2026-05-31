import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv

load_dotenv()

# Ganti dengan kredensial PostgreSQL Anda
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:Ary@24f1lkom@db.aczqiwhkconuwnyoslpc.supabase.co:5432/postgres?sslmode=require"
)

engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session