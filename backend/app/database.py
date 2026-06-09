import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from dotenv import load_dotenv

# Load .env dynamically from the backend root folder
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dotenv_path = os.path.join(base_dir, ".env")
load_dotenv(dotenv_path)

DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    import re
    # Mask password for secure logging (masks characters between ':' and '@' in credentials)
    masked_url = re.sub(r":([^@:]+)@", ":***@", DATABASE_URL)
    print("Connecting to:", masked_url)
else:
    raise ValueError("DATABASE_URL environment variable is not set!")

engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session