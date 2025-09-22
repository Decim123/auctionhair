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
                verify INTEGER DEFAULT 0,
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
                reg_date TEXT,
                liked_lots TEXT DEFAULT 0,
                lot_participant TEXT
            )
        ''')
        
        await db.execute('''
            CREATE TABLE IF NOT EXISTS verify (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                name_1 TEXT,
                name_2 TEXT,
                name_3 TEXT,
                date TEXT,
                status TEXT DEFAULT 'wait'
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS workers (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER UNIQUE,
                username TEXT,
                full_name TEXT,
                access_level INTEGER,
                status TEXT DEFAULT 'active',
                login TEXT UNIQUE,
                password TEXT
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS keys (
                id INTEGER PRIMARY KEY,
                key TEXT UNIQUE,
                access_level INTEGER
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS user_cards (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                number TEXT,
                system TEXT,
                logo TEXT
            )
        ''')
        
        await db.execute('''
            CREATE TABLE IF NOT EXISTS wallet_rub (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER UNIQUE,
                ballance REAL DEFAULT 0,
                frozen REAL DEFAULT 0,
                is_first INTEGER DEFAULT 1
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS wallet_history (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                action TEXT,
                description TEXT,
                status TEXT
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS frozen_history (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                action TEXT,
                description TEXT,
                status TEXT
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS lots (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                lot_type TEXT,
                long INTEGER,
                natural_color TEXT,
                now_color TEXT,
                type TEXT,
                age INTEGER,
                weight INTEGER,
                description TEXT,
                price INTEGER,
                period INTEGER,
                step INTEGER DEFAULT 500,
                views INTEGER DEFAULT 0,
                status INTEGER DEFAULT 0,
                high_price INTEGER DEFAULT 0,
                country TEXT,
                city TEXT,
                winner TEXT
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS lots_without_img (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER,
                lot_type TEXT,
                long INTEGER,
                natural_color TEXT,
                now_color TEXT,
                type TEXT,
                age INTEGER,
                weight INTEGER,
                description TEXT,
                price INTEGER,
                period INTEGER,
                step INTEGER,
                views INTEGER DEFAULT 0,
                status INTEGER DEFAULT 0,
                high_price INTEGER DEFAULT 0,
                country TEXT,
                city TEXT
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY,
                sender_id INTEGER,
                receiver_id INTEGER,
                lot_id INTEGER,
                content TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                is_read INTEGER DEFAULT 0,
                FOREIGN KEY (sender_id) REFERENCES users(tg_id),
                FOREIGN KEY (receiver_id) REFERENCES users(tg_id),
                FOREIGN KEY (lot_id) REFERENCES lots(id)
            )
        ''')

        await db.execute('''
            CREATE TABLE IF NOT EXISTS trading (
                id INTEGER PRIMARY KEY,
                trader_id INTEGER,
                lot_id INTEGER,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                price INTEGER,
                FOREIGN KEY (trader_id) REFERENCES users(tg_id),
                FOREIGN KEY (lot_id) REFERENCES lots(id)
            )
        ''')

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

        # Вставка ключа '123' с access_level = 3
        await db.execute('''
            INSERT OR IGNORE INTO keys (key, access_level)
            VALUES ('123', 3)
        ''')

        await db.commit()

async def main():
    await create_db()

asyncio.run(main())
