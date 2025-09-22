# db.py

import json
import random
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

url = 'https://hanna.ru.tuna.am'

DB_PATH = os.path.join(os.path.dirname(__file__), '../database/db.sqlite')
current_time = datetime.now(ZoneInfo('Europe/Moscow'))

COUNTRIES = {
  "Россия": [
    "Московская область",
    "Санкт-Петербург",
    "Ленинградская область",
    "Брянская область",
    "Краснодарский край",
    "Свердловская область",
    "Новосибирская область",
    "Республика Татарстан",
    "Челябинская область",
    "Ростовская область",
    "Республика Башкортостан",
    "Самарская область",
    "Республика Дагестан",
    "Нижегородская область",
    "Красноярский край",
    "Ставропольский край",
    "Пермский край",
    "Воронежская область",
    "Волгоградская область",
    "Иркутская область",
    "Омская область",
    "Тюменская область",
    "Республика Саха (Якутия)",
    "Ханты-Мансийский автономный округ",
    "Чеченская Республика",
    "Республика Коми",
    "Архангельская область",
    "Республика Бурятия",
    "Кемеровская область",
    "Алтайский край",
    "Оренбургская область",
    "Томская область",
    "Курская область",
    "Удмуртская Республика",
    "Республика Карелия",
    "Белгородская область",
    "Калининградская область",
    "Тульская область",
    "Ярославская область",
    "Ивановская область",
    "Владимирская область",
    "Калужская область",
    "Костромская область",
    "Рязанская область",
    "Смоленская область",
    "Тверская область",
    "Новгородская область",
    "Псковская область",
    "Мурманская область",
    "Республика Марий Эл",
    "Республика Мордовия",
    "Чувашская Республика",
    "Кировская область",
    "Республика Хакасия",
    "Республика Адыгея",
    "Республика Алтай",
    "Республика Калмыкия",
    "Республика Карачаево-Черкесия",
    "Республика Карелия",
    "Республика Северная Осетия — Алания",
    "Республика Тыва",
    "Республика Удмуртия",
    "Республика Хакасия",
    "Республика Чечня",
    "Республика Чувашия",
    "Сахалинская область",
    "Еврейская автономная область",
    "Ненецкий автономный округ",
    "Ханты-Мансийский автономный округ — Югра",
    "Чукотский автономный округ",
    "Ямало-Ненецкий автономный округ"
  ]
}

REGIONS = {
  "Московская область": ["Москва", "Подольск", "Химки", "Красногорск", "Мытищи"],
  "Брянская область": ["Брянск", "Клинцы", "Новозыбков", "Дятьково", "Сельцо"],
  "Ленинградская область": ["Санкт-Петербург", "Выборг", "Гатчина", "Тихвин", "Кингисепп"],
  "Краснодарский край": ["Краснодар", "Сочи", "Новороссийск", "Армавир", "Анапа"],
  "Свердловская область": ["Екатеринбург", "Нижний Тагил", "Каменск-Уральский", "Первоуральск", "Серов"],
  "Новосибирская область": ["Новосибирск", "Бердск", "Искитим", "Куйбышев", "Барабинск"],
  "Республика Татарстан": ["Казань", "Набережные Челны", "Нижнекамск", "Альметьевск", "Зеленодольск"],
  "Челябинская область": ["Челябинск", "Магнитогорск", "Златоуст", "Миасс", "Копейск"],
  "Ростовская область": ["Ростов-на-Дону", "Таганрог", "Шахты", "Волгодонск", "Новочеркасск"],
  "Республика Башкортостан": ["Уфа", "Стерлитамак", "Салават", "Нефтекамск", "Октябрьский"]
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
    "Отменен": 9,
    "Не состоялся": 10,
    "Ожидание оплаты": 11
    }

trade_type_mapping = {
    'Аукцион': 'auction',
    'Запрос предложений': 'ask',
    'Все': ['auction', 'ask']
}

actions = {
    1: {
        'type': 'freeze',
        'name': 'списание',
        'description': 'обеспечение аукциона'
    },
    2: {
        'type': 'add',
        'name': 'пополнение',
        'description': 'добавление средств на баланс'
    },
    3: {
        'type': 'subtract',
        'name': 'списание',
        'description': 'списание средств с баланса'
    },

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
        'id', 'tg_id', 'username', 'full_name', 'first_name', 'last_name', 'premium', 'lang',
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
        cursor = await db.execute('SELECT ballance, frozen, is_first FROM wallet_rub WHERE tg_id = ?', (tg_id,))
        result = await cursor.fetchone()
        await cursor.close()
        if result:
            balance, frozen_funds, is_first = result
            return {"balance": balance, "frozen_funds": frozen_funds, "is_first": is_first}
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
    query = "SELECT id FROM lots WHERE status != 10"
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
            if params.like == True:
                liked_lots = await like_check(params.tg_id)
                lot_ids = [lot_id for lot_id in lot_ids if lot_id in liked_lots]
            print('ЛОТЫ ПОСЛЕ СОТРИРОВКИ', lot_ids)
            print("PEOPLE",params.people)
            if params.people == True:
                print('people = True')
                async with db.execute("SELECT lot_participant FROM users WHERE tg_id = ?", (params.tg_id,)) as cur:
                    user_row = await cur.fetchone()
                    print('USER_ROW', user_row)
                    print('lot_participant:', user_row["lot_participant"])
                    if user_row["lot_participant"] is None:
                        lot_ids = []
                    elif user_row and user_row["lot_participant"]:
                        print("TEST")
                        # Преобразуем строку с id в список чисел
                        participant_lots = [int(x.strip()) for x in user_row["lot_participant"].split(",") if x.strip()]
                        print(participant_lots)
                        lot_ids = [lot_id for lot_id in lot_ids if lot_id in participant_lots]
                        print(lot_ids)
            
            return lot_ids
      
async def fetch_lot_by_id(lot_id: int) -> Optional[LotDetail]:
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute("SELECT * FROM lots WHERE id = ?", (lot_id,))
            row = await cursor.fetchone()
            await cursor.close()
            if row:
                data = dict(row)
                if isinstance(data.get('period'), str):
                    data['period'] = datetime.fromisoformat(data['period'])
                return LotDetail(**data)
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
        # Определяем порядок сортировки и дополнительные условия
        order_by = None
        additional_where = ""
        
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
        elif sort_by == "just_started":
            order_by = "period DESC"
            additional_where = " AND period != '0'"
        elif sort_by == "ending_soon":
            order_by = "period ASC"
            additional_where = " AND period != '0'"
        else:
            raise HTTPException(status_code=400, detail="Unsupported sort_by parameter")

        # Формируем плейсхолдеры для параметров запроса
        placeholders = ",".join(["?"] * len(lot_ids))
        
        # Базовый SQL-запрос
        query = f"""
            SELECT id FROM lots 
            WHERE id IN ({placeholders})
        """
        
        # Добавляем дополнительное условие, если требуется
        if additional_where:
            query += additional_where
        
        # Добавляем ORDER BY, если сортировка не по умолчанию
        if order_by:
            query += f" ORDER BY {order_by}"
        
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

async def like_check(tg_id: int) -> List[int]:
    query = """
    SELECT liked_lots
    FROM users
    WHERE tg_id = ?
    """
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(query, (tg_id,)) as cursor:
            row = await cursor.fetchone()
            if row and row['liked_lots']:
                liked_str = row['liked_lots']
                liked_array = [int(x) for x in liked_str.split(',') if x.isdigit()]
                return liked_array
            else:
                return []

async def get_media_files(lot_id: int, lot_type: str) -> List[dict]:
    print(lot_type)
    current_file_path = os.path.abspath(__file__)
    current_dir = os.path.dirname(current_file_path)

    if lot_type == 'ask':
        print(1)
        relative_directory = "../api/static/img/lots/asks/"
        exts = ['.png', '.jpg', '.mp4']
    else:
        print(2)
        relative_directory = "../api/static/img/lots/auctions/"
        exts = ['.png', '.jpg', '.mp4']

    directory = os.path.abspath(os.path.join(current_dir, relative_directory))
    print(directory)
    if not os.path.exists(directory):
        return []

    try:
        files = os.listdir(directory)
        print(files)
    except OSError:
        return []

    matching_files = [
        file_name for file_name in files
        if os.path.isfile(os.path.join(directory, file_name)) and
           file_name.startswith(f"{lot_id}_") and
           os.path.splitext(file_name)[1].lower() in exts
    ]

    media_list = []
    for f in matching_files:
        ext = os.path.splitext(f)[1].lower()
        file_url = f"{url}/static/img/lots/{'asks' if lot_type=='ask' else 'auctions'}/{f}"
        if ext == '.mp4':
            media_list.append({"url": file_url, "type": "video"})
        else:
            media_list.append({"url": file_url, "type": "image"})

    return media_list

async def get_messages(user_id: int, other_user_id: int, lot_id: int) -> List[MessageOut]:
    async with aiosqlite.connect(DB_PATH) as db:
        # Ставим is_read=1 только для сообщений, где user_id действительно тот, кому адресованы сообщения
        update_query = """
        UPDATE messages
        SET is_read = 1
        WHERE receiver_id = :current_user
          AND sender_id = :other_user
          AND lot_id = :lot
          AND is_read = 0
        """
        await db.execute(update_query, {"current_user": user_id, "other_user": other_user_id, "lot": lot_id})
        await db.commit()

        # Получаем все сообщения, где (sender, receiver) == (user_id, other_user_id) или (other_user_id, user_id)
        select_query = """
        SELECT id, sender_id, receiver_id, lot_id, content, timestamp, is_read
        FROM messages
        WHERE lot_id = :lot
          AND (
               (sender_id = :current_user AND receiver_id = :other_user)
            OR (sender_id = :other_user AND receiver_id = :current_user)
          )
        ORDER BY timestamp ASC
        """
        params = {"current_user": user_id, "other_user": other_user_id, "lot": lot_id}
        async with db.execute(select_query, params) as cursor:
            rows = await cursor.fetchall()

    result = []
    for row in rows:
        result.append(
            MessageOut(
                id=row[0],
                sender_id=row[1],
                receiver_id=row[2],
                lot_id=row[3],
                content=row[4],
                timestamp=row[5],
                is_read=bool(row[6])
            )
        )
    return result

async def user_chats(user_id: int) -> List[dict[str, int]]:
    query = """
    SELECT DISTINCT 
    CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END as receiver_id, 
    lot_id
    FROM messages
    WHERE sender_id = ? OR receiver_id = ?
    """
    params = (user_id, user_id, user_id)
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(query, params) as cursor:
            rows = await cursor.fetchall()
    result = []
    for row in rows:
        result.append({"receiver_id": row[0], "lot_id": row[1]})
    return result

async def get_trading_records_by_lot_id(lot_id: int) -> List[dict]:

    query = """
        SELECT trader_id, timestamp, price
        FROM trading
        WHERE lot_id = ?
    """

    records = []
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row  # Для получения результатов как словарей
            async with db.execute(query, (lot_id,)) as cursor:
                async for row in cursor:
                    record = {
                        'trader_id': row['trader_id'],
                        'timestamp': row['timestamp'],
                        'price': row['price']
                    }
                    records.append(record)
    except Exception as e:
        print(f"Ошибка при получении записей: {e}")
    print(records)
    return records

async def get_user_settings(tg_id: int) -> Settings:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT phone, email, lang FROM users WHERE tg_id = ?", (tg_id,)) as cursor:
            row = await cursor.fetchone()
            if row:
                phone, email, lang = row
                return Settings(
                    number=phone or "",
                    email=email or "",
                    lang=lang or ""
                )
            else:
                raise HTTPException(status_code=404, detail="Пользователь не найден")

# Функция для получения настроек уведомлений
async def get_user_notifications(tg_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            "SELECT notify_message, notify_recomendation, notify_sale, notify_trade_status FROM users WHERE tg_id = ?",
            (tg_id,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                notify_message, notify_recomendation, notify_sale, notify_trade_status = row
                return {
                    "notify_message": bool(notify_message),
                    "notify_recomendation": bool(notify_recomendation),
                    "notify_sale": bool(notify_sale),
                    "notify_trade_status": bool(notify_trade_status)
                }
            else:
                raise HTTPException(status_code=404, detail="Пользователь не найден")

async def get_statistic(tg_id: int) -> Statistic:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute(
            """
            SELECT reg_date,
                   lots_created_up, lots_created_down, lots_created_requested,
                   lots_rejected_up, lots_rejected_down, lots_rejected_requested,
                   lots_sold_up, lots_sold_down, lots_sold_requested,
                   lots_in_up, lots_in_down, lots_in_requested,
                   lots_fail_up, lots_fail_down, lots_fail_requested,
                   lots_argue, lots_argue_win, lots_argue_lose
            FROM users
            WHERE tg_id = ?
            """, (tg_id,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return Statistic(
                    reg_date=row[0] or "",
                    lots_created_up=row[1] or 0,
                    lots_created_down=row[2] or 0,
                    lots_created_requested=row[3] or 0,
                    lots_rejected_up=row[4] or 0,
                    lots_rejected_down=row[5] or 0,
                    lots_rejected_requested=row[6] or 0,
                    lots_sold_up=row[7] or 0,
                    lots_sold_down=row[8] or 0,
                    lots_sold_requested=row[9] or 0,
                    lots_in_up=row[10] or 0,
                    lots_in_down=row[11] or 0,
                    lots_in_requested=row[12] or 0,
                    lots_fail_up=row[13] or 0,
                    lots_fail_down=row[14] or 0,
                    lots_fail_requested=row[15] or 0,
                    lots_argue=row[16] or 0,
                    lots_argue_win=row[17] or 0,
                    lots_argue_lose=row[18] or 0
                )
            else:
                raise HTTPException(status_code=404, detail="Пользователь не найден")

async def get_profile_view(tg_id: int) -> ProfileViewResponse:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT username, rating FROM users WHERE tg_id = ?", (tg_id,)) as cursor:
            row = await cursor.fetchone()
            if row:
                username, rating = row
                return ProfileViewResponse(username=username or "", rating=rating or 0)
            else:
                raise HTTPException(status_code=404, detail="Пользователь не найден")

async def pro_check(tg_id):
    try:
        async with aiosqlite.connect(DB_PATH) as db:
            async with db.execute("SELECT tarif FROM users WHERE tg_id = ?", (tg_id,)) as cursor:
                row = await cursor.fetchone()
                return 1 if row and row[0] == "pro" else 0
    except Exception as e:
        print(f"Ошибка доступа к базе данных: {e}")
        return 0

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
    for idx, file in enumerate(images):
        extension = file.filename.split('.')[-1].lower()
        filename = f"{lot_id}_{idx+1}.{extension}"
        file_bytes = await file.read()
        mime_type, _ = mimetypes.guess_type(file.filename)
        print(f"Processing file: {file.filename}, MIME type: {mime_type}")
        if mime_type is not None and mime_type.startswith('video'):
            tasks.append(compress_and_save_video(file_bytes, filename, 1))
        elif extension in {'mp4', 'mov', 'avi', 'mkv', 'flv'}:
            tasks.append(compress_and_save_video(file_bytes, filename, 1))
        else:
            tasks.append(compress_and_save_image(file_bytes, filename, 1))
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
                status,
                country,
                city
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            3,
            country,
            city
        ))

        await db.execute(
            """
            UPDATE wallet_rub 
            SET is_first = 0
            WHERE tg_id = ?
            """,
            (tg_id,)
        )
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
    lot_type = 'ask' if int(weight) == 0 else 'auction'
    try:
        tg_id = int(tg_id)
        amount = int(amount)
        length = int(length)
        age = int(age)
        weight = int(weight)
        price = int(price)
        if auction_duration != '0':
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
            lot_type,
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

async def compress_and_save_userpic(image_bytes: bytes, file_name: str):
    images_dir = 'static/img/userpic/profile/'
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
    
async def send_message(msg: MessageBase) -> MessageOut:
    insert_query = """
    INSERT INTO messages (sender_id, receiver_id, lot_id, content, is_read)
    VALUES (?, ?, ?, ?, 0)
    """
    params = (msg.sender_id, msg.receiver_id, msg.lot_id, msg.content)
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(insert_query, params)
        await db.commit()
        async with db.execute("SELECT id, timestamp, is_read FROM messages WHERE rowid = last_insert_rowid()") as cursor:
            row = await cursor.fetchone()
    return MessageOut(
        id=row[0],
        sender_id=msg.sender_id,
        receiver_id=msg.receiver_id,
        lot_id=msg.lot_id,
        content=msg.content,
        timestamp=row[1],
        is_read=bool(row[2])
    )

async def do_balance_operation(tg_id: int, amount: float, action: int):
    try:
        if action not in actions:
            print(f"Unknown action {action} for user {tg_id}")
            return {"message": "Unknown action", "status": "error"}
        action_info = actions[action]
        operation_type = action_info['type']
        action_name = action_info['name']
        action_description = action_info['description']

        payment_success = True

        if not payment_success:
            print(f"Payment processing failed for user {tg_id}")
            return {"message": "Payment processing failed", "status": "error"}
        
        async with aiosqlite.connect(DB_PATH) as db:
            # 1. Считываем текущий баланс и замороженные средства
            cursor = await db.execute(
                "SELECT ballance, frozen FROM wallet_rub WHERE tg_id = ?",
                (tg_id,)
            )
            row = await cursor.fetchone()
            if not row:
                print(f"User {tg_id} not found")
                return {"message": "User not found", "status": "error"}
            
            current_balance, current_frozen = row
            new_balance = current_balance

            # 2. В зависимости от типа операции меняем баланс/замороженные средства
            if operation_type == 'add':
                new_balance += amount
                await db.execute(
                    "UPDATE wallet_rub SET ballance = ? WHERE tg_id = ?",
                    (new_balance, tg_id)
                )
                await db.execute('''
                    INSERT INTO wallet_history (tg_id, action, description, status)
                    VALUES (?, ?, ?, ?)
                ''', (tg_id, action_name, action_description, 'success'))

            elif operation_type == 'subtract':
                if current_balance < amount:
                    print(f"User {tg_id} has insufficient balance for subtraction")
                    return {"message": "Not enough balance", "status": "error"}
                new_balance -= amount
                await db.execute(
                    "UPDATE wallet_rub SET ballance = ? WHERE tg_id = ?",
                    (new_balance, tg_id)
                )
                await db.execute('''
                    INSERT INTO wallet_history (tg_id, action, description, status)
                    VALUES (?, ?, ?, ?)
                ''', (tg_id, action_name, action_description, 'success'))

            elif operation_type == 'freeze':
                if current_balance < amount:
                    print(f"User {tg_id} has insufficient balance to freeze")
                    return {"message": "Not enough balance to freeze", "status": "error"}
                new_balance -= amount
                new_frozen = current_frozen + amount
                await db.execute(
                    "UPDATE wallet_rub SET ballance = ?, frozen = ? WHERE tg_id = ?",
                    (new_balance, new_frozen, tg_id)
                )
                await db.execute('''
                    INSERT INTO wallet_history (tg_id, action, description, status)
                    VALUES (?, ?, ?, ?)
                ''', (tg_id, action_name, action_description, 'success'))
                await db.execute('''
                    INSERT INTO frozen_history (tg_id, action, description, status)
                    VALUES (?, ?, ?, ?)
                ''', (tg_id, action_name, action_description, 'success'))

            else:
                print(f"Unsupported operation type {operation_type} for user {tg_id}")
                return {"message": "Unsupported operation type", "status": "error"}

            # 3. Фиксируем все изменения в БД
            await db.commit()

        # 4. Возвращаем результат в зависимости от типа операции
        print(f"User {tg_id} performed {operation_type} of amount {amount}")
        if operation_type == 'freeze':
            return {"message": "Balance frozen successfully", "status": "success"}
        elif operation_type == 'add':
            return {"message": "Balance added successfully", "status": "success"}
        elif operation_type == 'subtract':
            return {"message": "Balance subtracted successfully", "status": "success"}

    except aiosqlite.Error as e:
        print(f"Database error for user {tg_id}: {e}")
        return {"message": "Database error occurred", "status": "error"}
    except Exception as e:
        print(f"Unexpected error for user {tg_id}: {e}")
        return {"message": "An unexpected error occurred", "status": "error"}
    
async def views_plus(lot_id: int) -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE lots SET views = views + 1 WHERE id = ?", (lot_id,))
        await db.commit()

async def update_status(id, status):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE lots SET status = ? WHERE id = ?", (status, id))
        await db.commit()

async def make_offer(lot_id: int, tg_id: int, amount: int, message: str):
    async with aiosqlite.connect(DB_PATH) as db:
        # Получаем данные по лоту
        async with db.execute("SELECT high_price, tg_id FROM lots WHERE id = ?", (lot_id,)) as cursor:
            row = await cursor.fetchone()
            if row:
                current_high_price, receiver_tg_id = row
                if amount > current_high_price:
                    await db.execute("UPDATE lots SET high_price = ? WHERE id = ?", (amount, lot_id))
            else:
                raise ValueError(f"Лот с id {lot_id} не найден.")

        # Добавляем запись в таблицу trading
        await db.execute(
            "INSERT INTO trading (trader_id, lot_id, timestamp, price) VALUES (?, ?, ?, ?)",
            (tg_id, lot_id, current_time, amount)
        )
        
        # Обновляем поле lot_participant в таблице users для tg_id
        async with db.execute("SELECT lot_participant FROM users WHERE tg_id = ?", (tg_id,)) as cursor:
            row = await cursor.fetchone()
            if row:
                current_lot_participant = row[0] or ""
                # Преобразуем строку в список (убираем лишние пробелы)
                participants = [p.strip() for p in current_lot_participant.split(',') if p.strip()] if current_lot_participant else []
                # Если текущий lot_id еще не добавлен, добавляем его
                if str(lot_id) not in participants:
                    participants.append(str(lot_id))
                    new_lot_participant = ",".join(participants)
                    await db.execute("UPDATE users SET lot_participant = ? WHERE tg_id = ?", (new_lot_participant, tg_id))
        
        await db.commit()

    # Отправляем сообщения
    msg = MessageBase(
        sender_id=tg_id,
        receiver_id=receiver_tg_id,
        lot_id=lot_id,
        content=f'^^Предложение: {amount}₽'
    )
    message_out: Optional[MessageOut] = await send_message(msg)
    
    if message != "":
        msg2 = MessageBase(
            sender_id=tg_id,
            receiver_id=receiver_tg_id,
            lot_id=lot_id,
            content=message
        )
        await send_message(msg2)
    
    return message_out

async def update_phone(tg_id: int, phone: str):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute("UPDATE users SET phone = ? WHERE tg_id = ?", (phone, tg_id))
        await db.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Пользователь не найден")


async def update_email(tg_id: int, email: str):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute("UPDATE users SET email = ? WHERE tg_id = ?", (email, tg_id))
        await db.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Пользователь не найден")

async def switch_notification(tg_id: int, number: int, value: bool):
    field_map = {
        1: "notify_message",
        2: "notify_recomendation",
        3: "notify_sale",
        4: "notify_trade_status"
    }
    if number not in field_map:
        raise HTTPException(status_code=400, detail="Неверный номер уведомления")
    field = field_map[number]
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            f"UPDATE users SET {field} = ? WHERE tg_id = ?",
            (int(value), tg_id)
        )
        await db.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Пользователь не найден")

async def set_rating(data: SetRatingRequest) -> SetRatingResponse:
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT rating_all FROM users WHERE tg_id = ?", (data.receiver_id,)) as cursor:
            row = await cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Пользователь не найден")
            rating_all_str = row[0] or ""
        
        ratings = {}
        if rating_all_str:
            entries = rating_all_str.split(',')
            for entry in entries:
                if ':' in entry:
                    parts = entry.split(':')
                    try:
                        key = int(parts[0])
                        value = int(parts[1])
                        ratings[key] = value
                    except:
                        continue
        
        ratings[data.tg_id] = data.rating
        new_rating_all = ','.join([f"{k}:{v}" for k, v in ratings.items()])
        if ratings:
            avg_rating = round(sum(ratings.values()) / len(ratings))
        else:
            avg_rating = 0
        
        await db.execute("UPDATE users SET rating_all = ?, rating = ? WHERE tg_id = ?",
                         (new_rating_all, avg_rating, data.receiver_id))
        await db.commit()
        return SetRatingResponse(average_rating=avg_rating)
    
async def change_username_in_db(tg_id: int, new_username: str):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute("UPDATE users SET username = ? WHERE tg_id = ?", (new_username, tg_id))
        await db.commit()
        if cursor.rowcount == 0:
            raise Exception("User not found")

#async def verify_user(tg_id: int, phone: str) -> int:
#    print(f"DEBUG: Запуск verify_user с tg_id={tg_id} и phone={phone}")
#    async with aiosqlite.connect(DB_PATH) as db:
#        print("DEBUG: Соединение с БД установлено")
#        async with db.execute("SELECT tg_id, verify FROM users WHERE phone = ?", (phone,)) as cursor:
#            row = await cursor.fetchone()
#            print(f"DEBUG: Результат запроса для phone={phone}: {row}")
#        if row is not None:
#            tg_id_2, verify_value = row
#            print(f"DEBUG: Найден пользователь: tg_id_2={tg_id_2}, verify={verify_value}")
#            if verify_value == 1:
#                if tg_id != tg_id_2:
#                    print(f"DEBUG: Несоответствие tg_id: входящий tg_id={tg_id} не равен найденному tg_id_2={tg_id_2}. Удаление пользователя с tg_id={tg_id}")
#                    await db.execute("DELETE FROM users WHERE tg_id = ?", (tg_id,))
#                print(f"DEBUG: Пользователь верифицирован. Возвращаем tg_id={tg_id_2}")
#                return tg_id_2
#            else:
#                print("DEBUG: Пользователь найден, но не верифицирован. Получение максимального id из таблицы")
#                async with db.execute("SELECT MAX(id) FROM users") as cursor_max:
#                    max_row = await cursor_max.fetchone()
#                    print(f"DEBUG: Результат запроса MAX(id): {max_row}")
#                    tg_id_2 = max_row[0] if max_row[0] is not None else 1
#                    print(f"DEBUG: Новый tg_id_2 установлен: {tg_id_2}")
#
#                print("DEBUG: Вставка нового пользователя")
#                await insert_user(
#                    tg_id=tg_id_2,
#                    username='Новый пользователь',
#                    full_name='не указанно',
#                    first_name='не указанно',
#                    last_name='не указанно',
#                    premium=False,
#                    lang='ru',
#                    phone=int(phone)
#                )
#                print("DEBUG: Пользователь вставлен. Обновление информации верификации")
#                await db.execute(
#                    "UPDATE users SET verify_date = ?, verify = 1 WHERE tg_id = ?",
#                    (current_time, tg_id_2)
#                )
#                if tg_id != tg_id_2:
#                    print(f"DEBUG: Несоответствие tg_id: входящий tg_id={tg_id} не равен новому tg_id_2={tg_id_2}. Удаление пользователя с tg_id={tg_id}")
#                    await db.execute("DELETE FROM users WHERE tg_id = ?", (tg_id,))
#                await db.commit()
#                print("DEBUG: Изменения сохранены. Возвращаем tg_id_2:", tg_id_2)
#                return tg_id_2
#        else:
#                print("DEBUG: Пользователь не найден и не верифицирован. Получение максимального id из таблицы")
#                async with db.execute("SELECT MAX(id) FROM users") as cursor_max:
#                    max_row = await cursor_max.fetchone()
#                    print(f"DEBUG: Результат запроса MAX(id): {max_row}")
#                    tg_id_2 = max_row[0] if max_row[0] is not None else 1
#                    print(f"DEBUG: Новый tg_id_2 установлен: {tg_id_2}")
#
#                print("DEBUG: Вставка нового пользователя")
#                await insert_user(
#                    tg_id=tg_id_2,
#                    username='Новый пользователь',
#                    full_name='не указанно',
#                    first_name='не указанно',
#                    last_name='не указанно',
#                    premium=False,
#                    lang='ru'
#                )
#                print("DEBUG: Пользователь вставлен. Обновление информации верификации")
#                await db.execute(
#                    "UPDATE users SET verify_date = ?, verify = 1 WHERE tg_id = ?",
#                    (current_time, tg_id_2)
#                )
#                if tg_id != tg_id_2:
#                    print(f"DEBUG: Несоответствие tg_id: входящий tg_id={tg_id} не равен новому tg_id_2={tg_id_2}. Удаление пользователя с tg_id={tg_id}")
#                    await db.execute("DELETE FROM users WHERE tg_id = ?", (tg_id,))
#                await db.commit()
#                print("DEBUG: Изменения сохранены. Возвращаем tg_id_2:", tg_id_2)
#                return tg_id_2

async def verify_user(tg_id_2, phone):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT * FROM users WHERE tg_id = ?", (phone,)) as cursor:
            user = await cursor.fetchone()
        print(f"User with tg_id={phone}: {user}")
        
        if user is None:
            print(f"No user found with tg_id={phone}. Inserting new user.")
            await db.execute("""
                INSERT INTO users (
                    tg_id,
                    username,
                    full_name,
                    first_name,
                    last_name,
                    premium,
                    lang,
                    phone,
                    verify,
                    verify_date
                ) VALUES (?, 'Новый пользователь', 'не указанно', 'не указанно', 'не указанно', ?, 'ru', ?, ?, ?)
            """, (phone, False, phone, 1, current_time))
            
            await db.execute('''
                INSERT INTO wallet_rub (tg_id) 
                VALUES (?)
            ''', (phone,))
            await db.commit()
            print("New user inserted.")
        
        print(f"Deleting user with tg_id={tg_id_2}.")
        await db.execute("DELETE FROM users WHERE tg_id = ?", (tg_id_2,))
        await db.commit()
        print("User deleted.")
        
    return int(phone)

async def change_offer(trader_id: int, lot_id: int, price: int):
    async with aiosqlite.connect(DB_PATH) as db:
        # Обновляем запись в таблице trading
        await db.execute(
            "UPDATE trading SET price = ?, timestamp = ? WHERE trader_id = ? AND lot_id = ?",
            (price, current_time, trader_id, lot_id)
        )
        # Обновляем поле high_price в таблице lots
        await db.execute(
            "UPDATE lots SET high_price = ? WHERE id = ?",
            (price, lot_id)
        )
        print('ставка изменена', price, current_time, trader_id, lot_id)
        await db.commit()

async def auto_bet():
    async with aiosqlite.connect(DB_PATH) as db:
        # Получаем все записи из таблицы autobet
        async with db.execute("SELECT id, trader_id, lot_id, step, max_bet, now_bet FROM autobet") as cursor:
            rows = await cursor.fetchall()

        for row in rows:
            autobet_id, trader_id, lot_id, step, max_bet, now_bet = row

            # Получаем поля status и high_price из таблицы lots по lot_id
            async with db.execute("SELECT status, high_price FROM lots WHERE id = ?", (lot_id,)) as lot_cursor:
                lot_row = await lot_cursor.fetchone()

            # Если лот не найден, переходим к следующей записи
            if lot_row is None:
                continue

            status, high_price = lot_row[0], lot_row[1]

            # Если статус лота не равен 0 или 3, удаляем запись из autobet
            if status not in (0, 3):
                await db.execute("DELETE FROM autobet WHERE id = ?", (autobet_id,))
                continue

            # Если high_price уже равен now_bet, то лучшее предложение установлено – обновлять не нужно
            if high_price == now_bet:
                continue

            # Вычисляем new_price
            new_price = high_price + step

            # Если условие выполнено, обновляем ставку через change_offer и обновляем now_bet
            if high_price > now_bet and new_price < max_bet:
                await change_offer(trader_id, lot_id, new_price)
                await db.execute("UPDATE autobet SET now_bet = ? WHERE id = ?", (new_price, autobet_id))

        await db.commit()

async def create_auto_bet(trader_id: int, lot_id: int, step: int, max_bet: int):
    async with aiosqlite.connect(DB_PATH) as db:
        # Проверяем, существует ли запись с таким trader_id и lot_id
        async with db.execute("SELECT id FROM autobet WHERE trader_id = ? AND lot_id = ?", (trader_id, lot_id)) as cursor:
            existing = await cursor.fetchone()
        if existing:
            return  # Запись уже существует, ничего не делаем

        # Получаем значение now_bet из таблицы trading для данного trader_id и lot_id
        async with db.execute("SELECT price FROM trading WHERE trader_id = ? AND lot_id = ?", (trader_id, lot_id)) as cursor:
            row = await cursor.fetchone()
        now_bet = row[0] if row is not None else 0

        # Вставляем новую запись в таблицу autobet
        await db.execute(
            "INSERT INTO autobet (trader_id, lot_id, step, max_bet, now_bet) VALUES (?, ?, ?, ?, ?)",
            (trader_id, lot_id, step, max_bet, now_bet)
        )
        await db.commit()


async def set_pro(tg_id: int) -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE users SET tarif = 'pro' WHERE tg_id = ?", (tg_id,))
        await db.commit()

async def change_status(id, status):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE lots SET status = ? WHERE id = ?", (status, id))
        await db.commit()  # Commit changes


async def set_winner(tg_id, id, pay = 0):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE lots SET winner = ? WHERE id = ?", (json.dumps([tg_id, pay]), id))
        await db.commit()

async def get_trade_price(tg_id, lot_id):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT price FROM trading WHERE trader_id = ? AND lot_id = ?", (tg_id, lot_id)) as cursor:
            row = await cursor.fetchone()
            return row[0] if row is not None else None