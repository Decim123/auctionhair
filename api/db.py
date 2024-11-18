# db.py

import aiosqlite
import asyncio
from datetime import datetime
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '../database/db.sqlite')

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

async def info(tg_id, fields):
    valid_fields = [
        'id', 'tg_id', 'full_name', 'first_name', 'last_name', 'premium', 'lang',
        'phone', 'email', 'rating', 'rating_all', 'city', 'tarif', 'verify',
        'notify_message', 'notify_recomendation', 'notify_sale', 'notify_trade_status',
        'verify_date', 'lots_created', 'lots_created_up', 'lots_created_down',
        'lots_created_requested', 'lots_rejected', 'lots_rejected_up',
        'lots_rejected_down', 'lots_rejected_requested', 'lots_sold', 'lots_sold_up',
        'lots_sold_down', 'lots_sold_requested', 'lots_in', 'lots_in_up',
        'lots_in_down', 'lots_in_requested', 'lots_fail', 'lots_fail_up',
        'lots_fail_down', 'lots_fail_requested', 'lots_argue', 'lots_argue_win',
        'lots_argue_lose', 'reg_date'
    ]

    # Проверяем, что все запрошенные поля существуют в базе данных
    for field in fields:
        if field not in valid_fields:
            raise ValueError(f"Invalid field requested: {field}")

    fields_str = ', '.join(fields)

    async with aiosqlite.connect(DB_PATH) as db:
        query = f"SELECT {fields_str} FROM users WHERE tg_id = ?"
        async with db.execute(query, (tg_id,)) as cursor:
            result = await cursor.fetchone()
            if result:
                # Создаем словарь из результатов
                data = dict(zip(fields, result))
                return data
            else:
                return None

async def check_key_exists(key: str) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('SELECT 1 FROM keys WHERE key = ?', (key,))
        result = await cursor.fetchone()
        return 1 if result else 0


async def get_access_level(key: str) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('SELECT access_level FROM keys WHERE key = ?', (key,))
        result = await cursor.fetchone()

        if result:
            access_level = result[0]
            await db.execute('DELETE FROM keys WHERE key = ?', (key,))
            await db.commit()
            return access_level
        else:
            return -1

async def check_worker_exists(tg_id: int) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute('SELECT COUNT(*) FROM workers WHERE tg_id = ?', (tg_id,)) as cursor:
            result = await cursor.fetchone()
            return 1 if result[0] > 0 else 0

# INPUT

async def add_verify_record(tg_id: str, name_1: str, name_2: str, name_3: str):

    now = datetime.now().strftime('%Y-%m-%d %H:%M')

    async with aiosqlite.connect(DB_PATH) as conn:
        cursor = await conn.cursor()

        try:
            await cursor.execute('''
                INSERT INTO verify (tg_id, name_1, name_2, name_3, date, status)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (tg_id, name_1, name_2, name_3, now, 'wait'))

            await cursor.execute('''
                UPDATE users
                SET verify = 2
                WHERE tg_id = ?
            ''', (tg_id,))

            await conn.commit()

        except aiosqlite.Error as e:
            print(f"Error: {e}")

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

async def add_worker_if_not_exists(tg_id, username, full_name, access_level):
    async with aiosqlite.connect(DB_PATH) as db:

        cursor = await db.execute('SELECT 1 FROM workers WHERE tg_id = ?', (tg_id,))
        existing_user = await cursor.fetchone()

        if not existing_user:
            await db.execute('''
                INSERT INTO workers (tg_id, username, full_name, access_level)
                VALUES (?, ?, ?, ?)
            ''', (tg_id, username, full_name, access_level))
            await db.commit()

async def update_worker_login_password(tg_id: int, login: str, password: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            UPDATE workers
            SET login = ?, password = ?
            WHERE tg_id = ?
        ''', (login, password, tg_id))
        await db.commit()

async def get_worker_by_login(login: str):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('SELECT * FROM workers WHERE login = ?', (login,))
        worker = await cursor.fetchone()
        
        if worker:
            return {
                "id": worker[0],
                "tg_id": worker[1],
                "username": worker[2],
                "full_name": worker[3],
                "access_level": worker[4],
                "status": worker[5],
                "login": worker[6],
                "password": worker[7]
            }
        return None

