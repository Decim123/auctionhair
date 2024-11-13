import aiosqlite
import asyncio

async def create_db():
    async with aiosqlite.connect('db.sqlite') as db:
        await db.execute('''
                CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER UNIQUE,
                username TEXT,
                full_name TEXT,
                first_name TEXT,
                last_name TEXT,
                premium BOOLEAN,
                lang TEXT,
                phone TEXT,
                email TEXT,
                rating INTEGER DEFAULT 100,
                rating_all TEXT,
                city TEXT DEFAULT 'Не указан',
                tarif TEXT DEFAULT 'Стандарт',
                verify BOOLEAN DEFAULT FALSE,
                notify_message BOOLEAN,
                notify_recomendation BOOLEAN,
                notify_sale BOOLEAN,
                notify_trade_status BOOLEAN,
                verify_date TEXT,
                lots_created INTEGER,
                lots_created_up INTEGER,
                lots_created_down INTEGER,
                lots_created_requested INTEGER,
                lots_rejected INTEGER,
                lots_rejected_up INTEGER,
                lots_rejected_down INTEGER,
                lots_rejected_requested INTEGER,
                lots_sold INTEGER,
                lots_sold_up INTEGER,
                lots_sold_down INTEGER,
                lots_sold_requested INTEGER,
                lots_in INTEGER,
                lots_in_up INTEGER,
                lots_in_down INTEGER,
                lots_in_requested INTEGER,
                lots_fail INTEGER,
                lots_fail_up INTEGER,
                lots_fail_down INTEGER,
                lots_fail_requested INTEGER,
                lots_argue INTEGER,
                lots_argue_win INTEGER,
                lots_argue_lose INTEGER,
                reg_date TEXT
            )
        ''')
        await db.commit()
        print("Таблица users успешно создана.")

async def insert_user(tg_id, full_name):
    async with aiosqlite.connect('db.sqlite') as db:
        await db.execute('''
            INSERT INTO users (tg_id, full_name) 
            VALUES (?, ?)
        ''', (tg_id, full_name))
        await db.commit()
        print(f"Пользователь {full_name} добавлен.")

async def get_users():
    async with aiosqlite.connect('db.sqlite') as db:
        async with db.execute('SELECT * FROM users') as cursor:
            users = await cursor.fetchall()
            for user in users:
                print(user)

# Асинхронный запуск функций
async def main():
    await create_db()
#    await insert_user(123456789, "Иван Иванов")
#    await get_users()

asyncio.run(main())
