import asyncio
from app.database import async_session
from app.crud import get_all_paid_transactions

async def main():
    async with async_session() as db:
        try:
            res = await get_all_paid_transactions(db)
            print(f"Result count: {len(res)}")
            for r in res:
                print(r.id, r.timestamp)
        except Exception as e:
            print("Error:", e)

asyncio.run(main())
