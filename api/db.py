# db.py

import subprocess
import mimetypes
from typing import List
import uuid
import aiosqlite
import asyncio
from datetime import datetime
import os
from api.models import *
from fastapi import HTTPException, UploadFile
from PIL import Image
from io import BytesIO
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

DB_PATH = os.path.join(os.path.dirname(__file__), '../database/db.sqlite')
current_time = datetime.now(ZoneInfo('Europe/Moscow'))

COUNTRIES = {
    "Россия": ["Московская область", "Брянская область"],
    "Беларусь": ["Минская область", "Гомельская область"]
}

REGIONS = {
    "Московская область": ["Москва", "Подольск"],
    "Брянская область": ["Брянск", "Клинцы", "Новозыбков"],
    "Минская область": ["Минск", "Борисов"],
    "Гомельская область": ["Гомель", "Речица"]
}

status_mapping = {
    "Все": [0,1,2,3,4],
    "Прием ставок": 0,
    "Состоялся": 1,
    "Завершен": 2,
    "Прием предложений": 3,
    "Определение победителя": 4,
    "Открыт спор": 5,
    "Оплачен": 6,
    "Отправлен": 7,
    "Получен": 8,
    "Отменен": 9
    }

trade_type_mapping = {
    'Аукцион': 'auction',
    'Запрос предложений': 'ask',
    'Все': ['auction', 'ask']
}

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
    
async def check_admin_exists(tg_id: int) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('SELECT 1 FROM workers WHERE tg_id = ?', (tg_id,))
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

async def get_workers():
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute("SELECT * FROM workers")
        rows = await cursor.fetchall()
        await cursor.close()
        workers = [dict(row) for row in rows]
        return workers

async def get_verify():
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute("SELECT * FROM verify")
        rows = await cursor.fetchall()
        await cursor.close()
        verify = [dict(row) for row in rows]
        return verify
    
async def get_wallet_data(tg_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('SELECT ballance, frozen FROM wallet_rub WHERE tg_id = ?', (tg_id,))
        result = await cursor.fetchone()
        await cursor.close()
        if result:
            balance, frozen_funds = result
            return {"balance": balance, "frozen_funds": frozen_funds}
        else:
            return None

async def get_user_auctions(tg_id: int) -> List[Auction]:
    auctions = []
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT * FROM lots WHERE tg_id = ? AND lot_type = 'auction'", (tg_id,)) as cursor:
            rows = await cursor.fetchall()
            for row in rows:
                auction = Auction(
                    id=row[0],
                    tg_id=row[1],
                    lot_type=row[2],
                    long=row[3],
                    natural_color=row[4],
                    now_color=row[5],
                    type=row[6],
                    age=row[7],
                    weight=row[8],
                    description=row[9],
                    price=row[10],
                    period=str(row[11]),
                    step=row[12],
                    views=row[13],
                    status=row[14],
                    high_price=row[15],
                )
                auctions.append(auction)
    return auctions

async def get_user_asks(tg_id: int) -> List[Ask]:
    asks = []
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT * FROM lots WHERE tg_id = ? AND lot_type = 'ask'", (tg_id,)) as cursor:
            rows = await cursor.fetchall()
            for row in rows:
                ask = Ask(
                    id=row[0],
                    tg_id=row[1],
                    lot_type=row[2],
                    long=row[3],
                    natural_color=row[4],
                    now_color=row[5],
                    type=row[6],
                    age=row[7],
                    weight=row[8],
                    description=row[9],
                    price=row[10],
                    period=str(row[11]),
                    step=row[12],
                    views=row[13],
                    status=row[14],
                    high_price=row[15],
                )
                asks.append(ask)
    return asks

async def get_user_region_country(tg_id: int) -> Optional[dict]:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('PRAGMA foreign_keys = ON')
        cursor = await db.execute('SELECT city FROM users WHERE tg_id = ?', (tg_id,))
        row = await cursor.fetchone()
        await cursor.close()
        if row:
            city = row[0]
            for region, cities in REGIONS.items():
                if city in cities:
                    for country, regions in COUNTRIES.items():
                        if region in regions:
                            return {"country": country, "region": region, "city": city}
    return None

async def fetch_sorted_lots(params: SortParameters) -> List[int]:
    query = "SELECT id FROM lots WHERE 1=1"
    values = []
    params.trade_type = 'Все' if params.trade_type is None else params.trade_type
    
    #async def show_filtred(now_query, now_values, filter):
    #    async with aiosqlite.connect(DB_PATH) as db:
    #        db.row_factory = aiosqlite.Row
    #        async with db.execute(now_query, tuple(now_values)) as cursor:
    #            rows = await cursor.fetchall()
    #            lot_ids = [row["id"] for row in rows]
    #            print(f'Сортировка по {filter} вернула',lot_ids)

    print('TRADE TYPE',params.trade_type)
    if params.trade_type and params.trade_type != 'Все':
        mapped_trade_type = trade_type_mapping.get(params.trade_type)
        if mapped_trade_type:
            query += " AND lot_type = ?"
            values.append(mapped_trade_type)
            #await show_filtred(query, values, '1')
    elif params.trade_type == 'Все':
        mapped_trade_types = trade_type_mapping.get('Все', [])
        if mapped_trade_types:
            placeholders = ','.join(['?'] * len(mapped_trade_types))
            query += f" AND lot_type IN ({placeholders})"
            values.extend(mapped_trade_types)
            #await show_filtred(query, values, '2')

    if params.trade_status and params.trade_status != 'Все':
        mapped_status = status_mapping.get(params.trade_status)
        if mapped_status is not None:
            if isinstance(mapped_status, list):
                placeholders = ','.join(['?'] * len(mapped_status))
                query += f" AND status IN ({placeholders})"
                values.extend(mapped_status)
                #await show_filtred(query, values, '3')
            else:
                query += " AND status = ?"
                values.append(mapped_status)
                #await show_filtred(query, values, '4')
    elif params.trade_status == 'Все':
        mapped_status = status_mapping.get('Все', [])
        if mapped_status:
            placeholders = ','.join(['?'] * len(mapped_status))
            query += f" AND status IN ({placeholders})"
            values.extend(mapped_status)
            #await show_filtred(query, values, '5')

    min_price = params.min_price if params.min_price is not None else 0
    max_price = params.max_price if params.max_price is not None else 50000
    query += " AND price BETWEEN ? AND ?"
    values.extend([min_price, max_price])
    #await show_filtred(query, values, '6')
    min_length = params.min_length if params.min_length is not None else 11
    max_length = params.max_length if params.max_length is not None else 119
    query += " AND long BETWEEN ? AND ?"
    values.extend([min_length, max_length])
    #await show_filtred(query, values, '7')
    natural_colors = params.natural_hair_colors if params.natural_hair_colors else ['Брюнет', 'Шатен', 'Русый', 'Рыжий', 'Блондин', 'Седой']
    if natural_colors:
        placeholders = ','.join(['?'] * len(natural_colors))
        query += f" AND natural_color IN ({placeholders})"
        values.extend(natural_colors)
        #await show_filtred(query, values, '8')
    current_colors = params.current_hair_colors if params.current_hair_colors else ['Брюнет', 'Шатен', 'Рыжий', 'Блондин', 'Русый', 'Седой']
    if current_colors:
        placeholders = ','.join(['?'] * len(current_colors))
        query += f" AND now_color IN ({placeholders})"
        values.extend(current_colors)
        #await show_filtred(query, values, '9')
    hair_types = params.hair_types if params.hair_types else ['Прямые', 'Вьющиеся', 'Волнистые', 'Мелкие кудри']
    if hair_types:
        placeholders = ','.join(['?'] * len(hair_types))
        query += f" AND type IN ({placeholders})"
        values.extend(hair_types)
        #await show_filtred(query, values, '10')

    if not (params.min_weight is None and params.max_weight is None):
        min_weight = params.min_weight if params.min_weight is not None else 11
        max_weight = params.max_weight if params.max_weight is not None else 999
        query += " AND weight BETWEEN ? AND ?"
        values.extend([min_weight, max_weight])
        #await show_filtred(query, values, '11')
        
    query += " ORDER BY status ASC, price ASC, long ASC, natural_color ASC, now_color ASC, type ASC, weight ASC"

    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(query, tuple(values)) as cursor:
            rows = await cursor.fetchall()
            lot_ids = [row["id"] for row in rows]
            print('ЛОТЫ ПОСЛЕ СОТРИРОВКИ', lot_ids)
            return lot_ids
      
async def fetch_lot_by_id(lot_id: int) -> Optional[Lot]:
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute("SELECT * FROM lots WHERE id = ?", (lot_id,))
            row = await cursor.fetchone()
            await cursor.close()
            if row:
                return Lot(**dict(row))
        return None
    except Exception as e:
        print(f"Error in fetch_lot_by_id: {e}")
        raise


async def get_lot_without_img_by_id(lot_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        query = '''
            SELECT * FROM lots_without_img WHERE id = ?
        '''
        async with db.execute(query, (lot_id,)) as cursor:
            result = await cursor.fetchone()
            return result

async def get_lot_without_img_by_id_m(lot_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        query = '''
            SELECT * FROM lots_without_img WHERE id = ?
        '''
        async with db.execute(query, (lot_id,)) as cursor:
            result = await cursor.fetchone()
            if result:
                # Получаем имена столбцов
                columns = [column[0] for column in cursor.description]
                # Создаем словарь из столбцов и результатов
                lot_info = dict(zip(columns, result))
                return lot_info
            else:
                return None
            
async def sort_by(sort_by: str, lot_ids: List[int]) -> List[int]:
    if not lot_ids:
        return []

    async with aiosqlite.connect(DB_PATH) as db:

        if sort_by == "default":
            return lot_ids
        elif sort_by == "price_asc":
            order_by = "price ASC"
        elif sort_by == "price_desc":
            order_by = "price DESC"
        elif sort_by == "length_shorter":
            order_by = "long ASC"
        elif sort_by == "length_longer":
            order_by = "long DESC"
        else:
            raise HTTPException(status_code=400, detail="Unsupported sort_by parameter")

        placeholders = ",".join(["?"] * len(lot_ids))
        query = f"""
            SELECT id FROM lots 
            WHERE id IN ({placeholders})
            ORDER BY {order_by}
        """

        try:
            cursor = await db.execute(query, lot_ids)
            rows = await cursor.fetchall()
            await cursor.close()
            sorted_lot_ids = [row[0] for row in rows]
            return sorted_lot_ids
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

async def short_lot_info(number: int, userId: int) -> dict:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row

        lot_query = '''
            SELECT step, period, lot_type, status, long, weight, views
            FROM lots
            WHERE id = ?
        '''
        async with db.execute(lot_query, (number,)) as cursor:
            lot = await cursor.fetchone()
            if not lot:
                raise ValueError("Лот не найден")

        user_query = '''
            SELECT liked_lots
            FROM users
            WHERE tg_id = ?
        '''
        async with db.execute(user_query, (userId,)) as cursor:
            user = await cursor.fetchone()
            if not user:
                raise ValueError("Пользователь не найден")

        liked_lots_str = user["liked_lots"]
        liked_lots = [int(id_.strip()) for id_ in liked_lots_str.split(',') if id_.strip().isdigit()]

        like = 1 if number in liked_lots else 0
        lot_type = 'Аукцион' if lot["lot_type"] == 'auction' else 'Запрос предложений'
        status = status = list(status_mapping.keys())[list(status_mapping.values()).index(0)]
        
        return {
            "like": like,
            "step": lot["step"],
            "period": lot["period"],
            "lot_type": lot_type,
            "status": status,
            "long": lot["long"],
            "weight": lot["weight"],
            "views": int(lot["views"]),
        }

async def lot_data_by_id(lot_id: int) -> Optional[dict]:
    query = """
    SELECT id, tg_id, lot_type, long, natural_color, now_color, type, age, weight, 
           description, price, period, step, views, status, high_price, country, city
    FROM lots
    WHERE id = ?
    """
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(query, (lot_id,)) as cursor:
            row = await cursor.fetchone()
            if row:
                lot = {key: row[key] for key in row.keys()}
                return lot
            else:
                return None

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
    tg_id = int(tg_id)

    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            CREATE TABLE IF NOT EXISTS wallet_rub (
                id INTEGER PRIMARY KEY,
                tg_id INTEGER UNIQUE,
                ballance REAL DEFAULT 0
            )
        ''')
        await db.execute('''
            INSERT INTO users (tg_id, username, full_name, first_name, last_name, premium, lang, reg_date) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (tg_id, username, full_name, first_name, last_name, premium, lang, reg_date))

        await db.execute('''
            INSERT INTO wallet_rub (tg_id) 
            VALUES (?)
        ''', (tg_id,))
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

async def generate_key(access_level: int):
    unique_key = str(uuid.uuid4())

    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            INSERT OR IGNORE INTO keys (key, access_level)
            VALUES (?, ?)
            ''', (unique_key, access_level))
        await db.commit()
    
    return unique_key

async def update_verification(tg_id: int, status: int):
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        await db.execute("BEGIN")
        if status == 1:
            await db.execute("""
                UPDATE verify
                SET status = 'success'
                WHERE tg_id = ?
            """, (tg_id,))
            cursor = await db.execute("""
                SELECT name_1, name_2
                FROM verify
                WHERE tg_id = ?
            """, (tg_id,))
            row = await cursor.fetchone()
            if row:
                await db.execute("""
                    UPDATE users
                    SET last_name = ?, first_name = ?, verify = 1
                    WHERE tg_id = ?
                """, (row['name_1'], row['name_2'], tg_id))
        elif status == 0:
            await db.execute("""
                UPDATE verify
                SET status = 'rejected'
                WHERE tg_id = ?
            """, (tg_id,))
            await db.execute("""
                UPDATE users
                SET verify = 0
                WHERE tg_id = ?
            """, (tg_id,))
        else:
            raise ValueError("Invalid status")
        await db.commit()

async def save_auction_to_db(
    tg_id: str,
    amount: str,
    length: str,
    age: str,
    weight: str,
    description: str,
    price: str,
    natural_color: str,
    current_color: str,
    hair_type: str,
    auction_duration: str,
    images: List[UploadFile]
):
    try:
        tg_id = int(tg_id)
        amount = int(amount)
        length = int(length)
        age = int(age)
        weight = int(weight)
        price = int(price)
        auction_duration = int(auction_duration)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid input data type")

    period = current_time + timedelta(days=auction_duration)
    period_str = period.isoformat()
    place_data = await get_user_region_country(tg_id)
    city = place_data["city"]
    country = place_data["country"]
    print(city, country)

    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('''
            INSERT INTO lots (
                tg_id,
                lot_type,
                long,
                natural_color,
                now_color,
                type,
                age,
                weight,
                description,
                price,
                period,
                step,
                country,
                city
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            tg_id,
            'auction',
            length,
            natural_color,
            current_color,
            hair_type,
            age,
            weight,
            description,
            price,
            period_str,
            amount,
            country,
            city
        ))
        await db.commit()
        lot_id = cursor.lastrowid

    tasks = []
    for idx, image in enumerate(images):
        extension = image.filename.split('.')[-1]
        filename = f"{lot_id}_{idx+1}.{extension}"
        image_bytes = await image.read()
        tasks.append(compress_and_save_image(image_bytes, filename))
    
    await asyncio.gather(*tasks)

    return lot_id

async def save_ask_to_db(
    tg_id: int,
    amount: str,
    length: str,
    age: str,
    description: str,
    natural_color: str,
    current_color: str,
    hair_type: str,
    images: List[UploadFile]
):
    try:
        amount = int(amount)
        length = int(length)
        age = int(age)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid input data type")

    place_data = await get_user_region_country(tg_id)
    city = place_data["city"]
    country = place_data["country"]

    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute('''
            INSERT INTO lots (
                tg_id,
                lot_type,
                long,
                natural_color,
                now_color,
                type,
                age,
                weight,
                description,
                price,
                period,
                step,
                country,
                city
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            tg_id,
            'ask',
            length,
            natural_color,
            current_color,
            hair_type,
            age,
            0,
            description,
            amount,
            0,
            0,
            country,
            city
        ))
        await db.commit()
        lot_id = cursor.lastrowid

    tasks = []
    for idx, file in enumerate(images):
        extension = file.filename.split('.')[-1].lower()
        filename = f"{lot_id}_{idx+1}.{extension}"
        file_bytes = await file.read()

        mime_type, _ = mimetypes.guess_type(file.filename)
        print(f"Processing file: {file.filename}, MIME type: {mime_type}")

        if mime_type and mime_type.startswith('video'):
            tasks.append(compress_and_save_video(file_bytes, filename, 0))
        elif extension in {'mp4', 'mov', 'avi', 'mkv', 'flv'}:
            tasks.append(compress_and_save_video(file_bytes, filename, 0))
        else:
            tasks.append(compress_and_save_image(file_bytes, filename, 0))

    await asyncio.gather(*tasks)

    return lot_id


async def save_auction_from_bot(
    tg_id: str,
    amount: str,
    length: str,
    age: str,
    weight: str,
    description: str,
    price: str,
    natural_color: str,
    current_color: str,
    hair_type: str,
    auction_duration: str,
    img: int
):
    table = 'lots' if img == 1 else 'lots_without_img'
    try:
        tg_id = int(tg_id)
        amount = int(amount)
        length = int(length)
        age = int(age)
        weight = int(weight)
        price = int(price)
        auction_duration = str(auction_duration) if img == 1 else (current_time + timedelta(days=int(auction_duration))).isoformat()
    except ValueError as e:
        raise HTTPException(status_code=400, detail="Invalid input data type")
    place_data = await get_user_region_country(tg_id)
    city = place_data["city"]
    country = place_data["country"]
    print(city, country)
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(f'''
            INSERT INTO {table} (
                tg_id,
                lot_type,
                long,
                natural_color,
                now_color,
                type,
                age,
                weight,
                description,
                price,
                period,
                step,
                country,
                city
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            tg_id,
            'auction',
            length,
            natural_color,
            current_color,
            hair_type,
            age,
            weight,
            description,
            price,
            auction_duration,
            amount,
            country,
            city
        ))
        await db.commit()
        lot_id = cursor.lastrowid
    return lot_id

async def update_city(tg_id: int, city: str):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('UPDATE users SET city = ? WHERE tg_id = ?', (city, tg_id))
        await db.commit()

async def compress_and_save_image(image_bytes: bytes, file_name: str, lot_type: int):
    lot_folder = 'auctions' if lot_type == 1 else 'asks'
    images_dir = f'static/img/lots/{lot_folder}'
    save_path = os.path.join(images_dir, file_name)
    try:
        image = Image.open(BytesIO(image_bytes))
        compressed_io = BytesIO()

        if image.format == 'JPEG':
            image.save(compressed_io, format='JPEG', quality=70, optimize=True)
        elif image.format == 'PNG':
            image.save(compressed_io, format='PNG', optimize=True)
        else:
            image = image.convert("RGB")
            image.save(compressed_io, format='JPEG', quality=70, optimize=True)
        compressed_io.seek(0)
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        loop = asyncio.get_running_loop()
        with open(save_path, "wb") as f:
            await loop.run_in_executor(None, f.write, compressed_io.read())
        print(f"Изображение сохранено и сжато по пути: {save_path}")
    except Exception as e:
        print(f"Ошибка при сжатии и сохранении изображения: {e}")
        raise e
    
async def compress_and_save_video(video_bytes: bytes, file_name: str, lot_type: int):
    lot_folder = 'auctions' if lot_type == 1 else 'asks'
    videos_dir = f'static/img/lots/{lot_folder}'
    save_path = os.path.join(videos_dir, file_name)
    try:
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        temp_path = save_path + ".temp"
        loop = asyncio.get_running_loop()
        
        # Сохранение временного видеофайла
        with open(temp_path, "wb") as f:
            await loop.run_in_executor(None, f.write, video_bytes)
        
        cmd = [
            'ffmpeg',
            '-i', temp_path,
            '-vcodec', 'libx264',
            '-crf', '28',
            save_path
        ]
        
        print(f"Running FFmpeg command: {' '.join(cmd)}")
        
        # Запуск FFmpeg асинхронно
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            print(f"FFmpeg error: {stderr.decode()}")
            raise Exception(stderr.decode())
        
        os.remove(temp_path)
        print(f"Видео сохранено и сжато по пути: {save_path}")
    except Exception as e:
        print(f"Ошибка при сжатии и сохранении видео: {e}")
        raise e

async def like(userId: int, lot_id: int, value: int) -> dict:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        user_query = '''
            SELECT liked_lots
            FROM users
            WHERE tg_id = ?
        '''
        async with db.execute(user_query, (userId,)) as cursor:
            user = await cursor.fetchone()
            if not user:
                raise ValueError("Пользователь не найден")

        liked_lots_str = user["liked_lots"]
        if liked_lots_str.strip() == '0' or not liked_lots_str.strip():
            liked_lots = []
        else:
            liked_lots = [int(id_.strip()) for id_ in liked_lots_str.split(',') if id_.strip().isdigit()]

        if value == 1:
            if lot_id not in liked_lots:
                liked_lots.append(lot_id)
        elif value == 0:
            if lot_id in liked_lots:
                liked_lots.remove(lot_id)
        else:
            raise ValueError("Неверное значение для параметра value. Ожидалось 0 или 1.")

        if liked_lots:
            new_liked_lots_str = ','.join(map(str, liked_lots))
        else:
            new_liked_lots_str = '0'

        update_query = '''
            UPDATE users
            SET liked_lots = ?
            WHERE tg_id = ?
        '''
        await db.execute(update_query, (new_liked_lots_str, userId))
        await db.commit()

        operation = "добавлено" if value == 1 else "удалено"
        return {
            "success": True,
            "message": f"Лот с ID {lot_id} успешно {operation} в liked_lots."
        }