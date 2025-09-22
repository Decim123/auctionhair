import asyncio
import aiosqlite

DB_PATH = 'database/db.sqlite'

async def add_lot_participant_column():
    async with aiosqlite.connect("database/db.sqlite") as db:
        await db.execute("ALTER TABLE users ADD COLUMN lot_participant TEXT")
        await db.commit()

async def create_autobet_table():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            CREATE TABLE IF NOT EXISTS autobet (
                id INTEGER PRIMARY KEY,
                trader_id INTEGER,
                lot_id INTEGER,
                step INTEGER,
                max_bet INTEGER,
                now_bet INTEGER,
                FOREIGN KEY (trader_id) REFERENCES users(tg_id),
                FOREIGN KEY (lot_id) REFERENCES lots(id)
            )
        ''')
        await db.commit()

if __name__ == "__main__":
    asyncio.run(create_autobet_table())