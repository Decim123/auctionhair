# db.py

import aiosqlite
import asyncio
from datetime import datetime
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '../database/db.sqlite')

async def create_db():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER UNIQUE,
                full_name TEXT,
                first_name TEXT,
                last_name TEXT,
                premium BOOLEAN,
                lang TEXT,
                phone TEXT,
                email TEXT,
                rating INTEGER,
                rating_all TEXT,
                city TEXT,
                tarif TEXT,
                verify BOOLEAN,
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

# OUTPUT

async def user_exists(tg_id):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute('SELECT COUNT(*) FROM users WHERE tg_id = ?', (tg_id,)) as cursor:
            result = await cursor.fetchone()
            return result[0] > 0
        
async def get_username(tg_id):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute('SELECT username FROM users WHERE tg_id = ?', (tg_id,)) as cursor:
            result = await cursor.fetchone()
            if result:
                return {'username': result[0]}
            else:
                return None

# INPUT

async def insert_user(tg_id, username, full_name, first_name, last_name, premium, lang):
    reg_date = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    premium = premium if premium is not None else False
    lang = lang if lang is not None else ''
    first_name = first_name if first_name is not None else ''
    last_name = last_name if last_name is not None else ''
    full_name = full_name if full_name is not None else ''
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            INSERT INTO users (tg_id, username, full_name, first_name, last_name, premium, lang, reg_date) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (tg_id, username, full_name, first_name, last_name, premium, lang, reg_date))
        await db.commit()
        print(f"Пользователь {full_name} добавлен.")
