import base64
import math
from pathlib import Path
from random import randint
from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
import httpx
from .models import *
from db import *
import shutil
import os
import requests
from PIL import Image
from io import BytesIO

TEMP_DB_PATH = "temp.sqlite"
TEMP_MEDIA_DIR = "static/img/temp_media"
BASE_API_URL = "https://hanna.ru.tuna.am"
TELEGRAM_BOT_TOKEN = '8138748896:AAGz_PbbiXxPZLT1POm2Si586iWlTFCN3Qk'
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

api_router = APIRouter()

async def create_temp_media_table():
    if not os.path.exists(TEMP_MEDIA_DIR):
        os.makedirs(TEMP_MEDIA_DIR)

    async with aiosqlite.connect(TEMP_DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS temp_media (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tg_id INTEGER,
                file_path TEXT,
                created_at TEXT
            )
        """)
        await db.commit()

@api_router.post('/user_info')
async def get_user_info(request: UserRequest):
    tg_id = request.tg_id
    function = request.function

    user_data = await get_username(tg_id)
    if user_data:
        if function in user_data:
            return {function: user_data[function]}
        else:
            raise HTTPException(status_code=404, detail='Function not found for this user')
    else:
        raise HTTPException(status_code=404, detail='User not found')

@api_router.post('/info')
async def get_info(request: InfoRequest):
    tg_id = request.tg_id
    fields = request.fields

    try:
        user_data = await info(tg_id, fields)
        if user_data:
            print(user_data)
            return user_data
        else:
            raise HTTPException(status_code=404, detail='User not found')
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@api_router.post('/tg_start')
async def tg_start(tg_start: TgStart):
    print("Получены данные пользователя:")
    print(tg_start)
    tg_id = tg_start.user_id

    if not await user_exists(tg_id):
        await insert_user(
            tg_id=tg_id,
            username=tg_start.username,
            full_name=tg_start.full_name,
            first_name=tg_start.first_name,
            last_name=tg_start.last_name,
            premium=tg_start.is_premium,
            lang=tg_start.language_code
        )
    else:
        print(f"Пользователь {tg_start.full_name} уже существует в базе данных.")
    return {'status': 'success', 'received_data': tg_start}

@api_router.post('/app_start')
async def tg_start():
    tg_id = int( '1000' + str(randint(1000000000, 9999999999)))

    if not await user_exists(tg_id):
        await insert_user(
            tg_id=tg_id,
            username='Новый пользователь',
            full_name='не указанно',
            first_name='не указанно',
            last_name='не указанно',
            premium=False,
            lang='ru'
        )
    else:
        print(f"Пользователь {tg_id} уже существует в базе данных.")
    return {'tg_id': tg_id}

@api_router.post("/save_user_photo")
async def save_user_photo(tg_id: int = Form(...), photo: UploadFile = Form(...)):
    try:
        image_bytes = await photo.read()
        await compress_and_save_userpic(image_bytes, f"{tg_id}.jpg")
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@api_router.post("/verify_try")
async def verify_try(
    tg_id: str = Form(...),
    name_1: str = Form(...),
    name_2: str = Form(...),
    name_3: str = Form(...),
    image: UploadFile = File(...)
):
    await add_verify_record(tg_id, name_1, name_2, name_3)

    file_type = str(image.filename).split('.')[1]

    upload_directory = "../staic/img/userpic/verify"
    os.makedirs(upload_directory, exist_ok=True)
    file_location = os.path.join(upload_directory, f'{tg_id}.{file_type}')

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    return {"status": "success", "message": "Data received and image saved."}

@api_router.post("/check_key")
async def check_key(key_model: KeyModel):
    try:
        key_exists = await check_key_exists(key_model.key)
        return {"exists": key_exists}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@api_router.post("/check_admin")
async def check_key(admin_model: AdminModel):
    try:
        admin_exists = await check_admin_exists(admin_model.tg_id)
        return {"exists": admin_exists}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@api_router.post("/add_worker")
async def create_worker(worker: InitWorker):
    try:
        access_level = await get_access_level(worker.key)
        await add_worker_if_not_exists(worker.tg_id, worker.username, worker.full_name, access_level)
        return {"message": "Worker added successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@api_router.get("/wallet")
async def wallet_data(
    tg_id: int = Query(..., description="Telegram ID пользователя"),
    lot_id: Optional[int] = Query(None, description="Lot ID")
):
    print('LOT ID: ', lot_id)
    if lot_id is not None and lot_id != 0:
        lot_info = await lot_data_by_id(lot_id)
        max_price = lot_info.get('high_price')
        step = lot_info.get('step')
        data = await get_wallet_data(tg_id)
        data['max_price'] = max_price
        data['step'] = step
    else:
        data = await get_wallet_data(tg_id) 
    if data:
        print(data)
        return data
    else:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
@api_router.post("/auction_create")
async def auction_create(
    tg_id: str = Form(...),
    amount: str = Form(...),
    length: str = Form(...),
    age: str = Form(...),
    weight: str = Form(...),
    description: str = Form(...),
    price: str = Form(...),
    natural_color: str = Form(...),
    current_color: str = Form(...),
    hair_type: str = Form(...),
    auction_duration: str = Form(...),
    images: List[UploadFile] = File(...)
):
    lot_id = await save_auction_to_db(
        tg_id,
        amount,
        length,
        age,
        weight,
        description,
        price,
        natural_color,
        current_color,
        hair_type,
        auction_duration,
        images
    )
    return {"status": "success", "lot_id": lot_id}

@api_router.post("/ask_create")
async def create_ask(
    tg_id: int = Form(...),
    amount: str = Form(...),
    length: str = Form(...),
    age: str = Form(...),
    description: str = Form(...),
    natural_color: str = Form(...),
    current_color: str = Form(...),
    hair_type: str = Form(...),
    images: List[UploadFile] = File(...)
):
    lot_id = await save_ask_to_db(
        tg_id,
        amount,
        length,
        age,
        description,
        natural_color,
        current_color,
        hair_type,
        images
    )
    return JSONResponse(content={"message": "Данные получены успешно", "lot_id": lot_id}, status_code=201)

@api_router.post("/get_auctions")
async def get_auctions(request: GetAuctionsRequest):
    tg_id = request.tg_id
    auctions = await get_user_auctions(tg_id)
    print(auctions)
    return [auction.dict() for auction in auctions]

@api_router.post("/get_asks")
async def get_auctions(request: GetAsksRequest):
    tg_id = request.tg_id
    asks = await get_user_asks(tg_id)
    print(asks)
    return [ask.dict() for ask in asks]

@api_router.get("/get_auction_media", response_model=List[str])
async def get_auction_photo(id: int = Query(..., description="Auction ID")):
    current_file_path = os.path.abspath(__file__)
    current_dir = os.path.dirname(current_file_path)
    relative_directory = "../static/img/lots/auctions/"
    directory = os.path.abspath(os.path.join(current_dir, relative_directory))
    if not os.path.exists(directory):
        raise HTTPException(status_code=404, detail="Directory not found")

    try:
        files = os.listdir(directory)
    except OSError as e:
        raise HTTPException(status_code=500, detail=f"Error accessing directory: {e}")

    matching_files = [
        file_name for file_name in files
        if os.path.isfile(os.path.join(directory, file_name)) and
           file_name.startswith(f"{id}_") and
           os.path.splitext(file_name)[1].lower() in ['.png', '.jpg', '.mp4']
    ]

    print(f"Найденные файлы для аукциона {id}: {matching_files}")
    
    return matching_files

@api_router.get("/get_asks_media", response_model=List[str])
async def get_auction_photo(id: int = Query(..., description="Auction ID")):
    current_file_path = os.path.abspath(__file__)
    current_dir = os.path.dirname(current_file_path)
    relative_directory = "../static/img/lots/asks/"
    directory = os.path.abspath(os.path.join(current_dir, relative_directory))
    if not os.path.exists(directory):
        raise HTTPException(status_code=404, detail="Directory not found")

    try:
        files = os.listdir(directory)
    except OSError as e:
        raise HTTPException(status_code=500, detail=f"Error accessing directory: {e}")

    matching_files = [
        file_name for file_name in files
        if os.path.isfile(os.path.join(directory, file_name)) and
           file_name.startswith(f"{id}_") and
           os.path.splitext(file_name)[1].lower() in ['.png', '.jpg', '.mp4']
    ]

    print(f"Найденные файлы для запроса {id}: {matching_files}")
    
    return matching_files

@api_router.post("/sort", response_model=SortResponse)
async def sort_lots(params: SortParameters):
    print(f"Received params: {params}")
    try:
        lots = await fetch_sorted_lots(params)
        print(f"Fetched lot IDs: {lots}")
        return SortResponse(lots=lots)
    except Exception as e:
        print(f"Error in sort_lots: {e}")
        raise HTTPException(status_code=500, detail="Внутренняя ошибка сервера")

@api_router.get("/get_lot_data", response_model=LotDetailResponse)
async def get_lot_data(id: int = Query(..., description="Идентификатор лота")):
    try:
        lot = await fetch_lot_by_id(id)
        if not lot:
            raise HTTPException(status_code=404, detail="Лот не найден")
        print('LOT_DATA', lot)
        return LotDetailResponse(lot=lot)
    except Exception as e:
        print(f"Error in get_lot_data: {e}")
        raise HTTPException(status_code=500, detail="Внутренняя ошибка сервера")
    
@api_router.post("/city_pick")
async def city_pick(request: Request):
    try:
        data = await request.json()
        tg_id = data.get('tg_id')
        selected_city = data.get('selected_city')
        await update_city(tg_id, selected_city)
        print(f"Received tg_id: {tg_id}, selected_city: {selected_city}")
        return JSONResponse(content={"status": "success"}, status_code=200)
    except Exception as e:
        print(f"Error processing city_pick: {e}")
        return JSONResponse(content={"status": "error", "message": str(e)}, status_code=400)

@api_router.get("/get_regions")
async def get_regions():
    print(COUNTRIES, REGIONS)
    return JSONResponse(content={"COUNTRIES": COUNTRIES, "REGIONS": REGIONS}, status_code=200)

templates = Jinja2Templates(directory="api/templates")

@api_router.get("/media_picker", response_class=HTMLResponse)
async def media_picker(request: Request, userId: int):
    return templates.TemplateResponse("media_picker.html", {"request": request, "userId": userId})

@api_router.post("/lot_without_img")
async def lot_without_img(
    tg_id: int = Form(...),
    amount: str = Form(...),
    length: str = Form(...),
    age: str = Form(...),
    weight: str = Form(...),
    description: str = Form(...),
    price: str = Form(...),
    natural_color: str = Form(...),
    current_color: str = Form(...),
    hair_type: str = Form(...),
    auction_duration: str = Form(...)
):
    lot_data = LotData(
        tg_id=tg_id,
        amount=amount,
        length=length,
        age=age,
        weight=weight,
        description=description,
        price=price,
        natural_color=natural_color,
        current_color=current_color,
        hair_type=hair_type,
        auction_duration=auction_duration
    )

    data = lot_data.dict()
    print("Полученные данные:")
    print(data)
    lot_id = await save_auction_from_bot(tg_id, amount, length, age, weight, description, price, natural_color, current_color, hair_type, auction_duration, 0)
    message_text = (
        f"Чтобы завершить создание, прикрепите изображения"
    )
    callback_data = (
        f"get_lot_media_{data['tg_id']}_{lot_id}"
        )

    inline_keyboard = {
        "inline_keyboard": [
            [
                {
                    "text": "Прикрепить изображения",
                    "callback_data": callback_data
                }
            ]
        ]
    }

    # Делаем запрос к Telegram Bot API для отправки сообщения
    send_message_url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {
        "chat_id": data["tg_id"],
        "text": message_text,
        "reply_markup": inline_keyboard
    }

    response = requests.post(send_message_url, json=payload)

    if response.status_code == 200:
        print("Сообщение успешно отправлено пользователю.")
    else:
        print(f"Ошибка при отправке сообщения: {response.status_code}")
        print(response.text)

    return JSONResponse(content={"status": "success", "data": data})

@api_router.post('/get_lot_without_img')
async def get_lot_without_img(request: Request):
    try:
        data = await request.json()
        print("Полученные данные:", data)
        lot_id = data.get("lot_id_withot_img")
        if lot_id is None:
            return JSONResponse(content={"error": "lot_id_withot_img is required"}, status_code=400)
        lot_info = await get_lot_without_img_by_id(lot_id)
        print(lot_info)
        return JSONResponse(content={"status": "success", "data": lot_info})
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@api_router.post("/create_lot_from_bot")
async def create_lot_from_bot(
    lot_id: int = Form(...),
    files: List[UploadFile] = File(...)
):  
    lot_info = await get_lot_without_img_by_id_m(lot_id)
    if not lot_info:
        raise HTTPException(status_code=404, detail="Лот не найден")
    
    new_lot_id = await save_auction_from_bot(
        tg_id=str(lot_info['tg_id']),
        amount=str(lot_info['step']),
        length=str(lot_info['long']),
        age=str(lot_info['age']),
        weight=str(lot_info['weight']),
        description=lot_info['description'],
        price=str(lot_info['price']),
        natural_color=lot_info['natural_color'],
        current_color=lot_info['now_color'],
        hair_type=lot_info['type'],
        auction_duration=str(lot_info['period']),
        img=1
    )
    print(lot_info['weight'])
    if lot_info['weight'] == 0:
        for idx, file in enumerate(files):
            try:
                content_type = file.content_type
                contents = await file.read()
                print(content_type)
                if content_type.startswith("video"):
                    file_extension = "mp4"
                    file_name = f"{new_lot_id}_{idx+1}.{file_extension}"
                    await compress_and_save_video(contents, file_name, 0)
                
                elif content_type.startswith("image"):
                    file_extension = "jpg"
                    file_name = f"{new_lot_id}_{idx+1}.{file_extension}"
                    await compress_and_save_image(contents, file_name, 0)
                
                else:
                    raise HTTPException(status_code=400, detail=f"Unsupported file type: {content_type}")
            
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Error processing file {file.filename}: {str(e)}")
    else:
        for idx, photo in enumerate(files):
            contents = await photo.read()
            file_name = f"{new_lot_id}_{idx+1}.jpg"
            await compress_and_save_image(contents, file_name, 1)
    
    return {"status": "success"}

@api_router.post("/sort_by", response_model=SortResponse)
async def sort_by_lots(request: SortByRequest):
    print('SORT_BY', request.sort_by, request.lots)
    sorted_lots = await sort_by(request.sort_by, request.lots)
    return SortResponse(lots=sorted_lots)

@api_router.post("/get_lot_short_info", response_model=LotShortInfoResponse)
async def get_lot_short_info(request: LotShortInfoRequest):
    try:
        result = await short_lot_info(request.number, request.userId)
        return LotShortInfoResponse(**result)
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Внутренняя ошибка сервера")
    
@api_router.post("/like", response_model=LikeResponse)
async def like_lot(request: LikeRequest):
    try:
        result = await like(request.userId, request.lot_id, 1)
        return LikeResponse(success=result["success"], message=result["message"])
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Внутренняя ошибка сервера")

@api_router.post("/unlike", response_model=LikeResponse)
async def unlike_lot(request: LikeRequest):
    try:
        result = await like(request.userId, request.lot_id, 0)
        return LikeResponse(success=result["success"], message=result["message"])
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Внутренняя ошибка сервера")
    
@api_router.post("/get_lot_data_by_id", response_model=LotDataFull)
async def get_lot_data_by_id(lot_id: LotID):
    lot = await lot_data_by_id(lot_id.lot_id)
    if lot:
        return lot
    else:
        raise HTTPException(status_code=404, detail="Лот не найден")

@api_router.post("/trades")
async def get_trades(req: TradeRequest):
    pro = await pro_check(req.tg_id)
    liked_lots = []
    if req.tg_id is not None:
        liked_lots = await like_check(req.tg_id)
        print('LIKED :', liked_lots)

    sorted_lot_ids = await sort_by(req.sort_by, req.lot_ids)
    results = []
    for lot_id in sorted_lot_ids:
        lot_info = await lot_data_by_id(lot_id)
        if lot_info is None:
            continue
        lot_type = lot_info.get('lot_type', 'asks')
        media = await get_media_files(lot_id, lot_type)
        is_liked = lot_id in liked_lots
        results.append({
            "lot_id": lot_id,
            "step": lot_info.get('high_price', 0) if pro == 1 else 1111111,
            "period": lot_info.get('period', ''),
            "lot_type": lot_type,
            "status": lot_info.get('status', ''),
            "long": lot_info.get('long', 0),
            "weight": lot_info.get('weight', 0),
            "views": lot_info.get('views', 0),
            "like": is_liked,
            "media": media
        })
    print(results)
    return results

@api_router.get("/messages", response_model=List[MessageOut])
async def messages(
    user_id: int,
    other_user_id: int,
    lot_id: int
):
    return await get_messages(user_id, other_user_id, lot_id)

@api_router.post("/messages", response_model=MessageOut)
async def create_message(msg: MessageBase):
    return await send_message(msg)

@api_router.get("/user_chats")
async def get_user_chats(user_id: int):
    return await user_chats(user_id)

@api_router.post("/ask_without_media_create")
async def ask_without_media_create(
    tg_id: str = Form(...),
    amount: str = Form(...),
    length: str = Form(...),
    age: str = Form(...),
    description: str = Form(...),
    natural_color: str = Form(...),
    current_color: str = Form(...),
    hair_type: str = Form(...),
):

    lot_data = LotData(
        tg_id=tg_id,
        amount=amount,
        length=length,
        age=age,
        weight='0',
        description=description,
        price='0',
        natural_color=natural_color,
        current_color=current_color,
        hair_type=hair_type,
        auction_duration='0'
    )

    data = lot_data.dict()
    print("Полученные данные:")
    print(data)
    lot_id = await save_auction_from_bot(tg_id, amount, length, age, 0, description, 0, natural_color, current_color, hair_type, 0, 0)
    
    message_text = (
        f"Чтобы завершить создание, прикрепите изображения или видео"
    )
    callback_data = (
        f"get_lot_media_{data['tg_id']}_{lot_id}_ask"
        )

    inline_keyboard = {
        "inline_keyboard": [
            [
                {
                    "text": "Прикрепить изображения",
                    "callback_data": callback_data
                }
            ]
        ]
    }

    send_message_url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {
        "chat_id": data["tg_id"],
        "text": message_text,
        "reply_markup": inline_keyboard
    }

    response = requests.post(send_message_url, json=payload)

    if response.status_code == 200:
        print("Сообщение успешно отправлено пользователю.")
    else:
        print(f"Ошибка при отправке сообщения: {response.status_code}")
        print(response.text)

    return JSONResponse(content={"message": "Данные получены успешно", "lot_id": lot_id}, status_code=201)

@api_router.post("/lot_trades", response_model=List[LotTradeResponse])
async def get_lot_trades(data: LotTradeRequest):
    
    pro = await pro_check(data.tg_id)
    lot_id = data.lot_id
    await views_plus(lot_id)
    trading_records = await get_trading_records_by_lot_id(lot_id)

    # Если торговых записей нет, возвращаем специальный ответ с pro
    if not trading_records:
        response = LotTradeResponse(
            avatar_url=f"{BASE_API_URL}api/static/img/userpic/no.png",    # Можно оставить пустым или задать значение по умолчанию
            rating=0,
            username="jshdjahSJDHJhsjmndasdjh",   # Или любое другое значение, сигнализирующее о pro
            price=5000 if pro == 1 else 0,
            trader_id=0
        )
        return [response]

    # Собираем уникальные trader_id для оптимизации запросов
    unique_trader_ids = list({record['trader_id'] for record in trading_records})

    # Получаем информацию о трейдерах
    trader_infos = {}
    for trader_id in unique_trader_ids:
        trader_info = await info(trader_id, ['username', 'rating'])
        if trader_info:
            trader_infos[trader_id] = trader_info
        else:
            # Если информация не найдена, можно установить значения по умолчанию
            trader_infos[trader_id] = {'full_name': 'Unknown', 'rating': 0}

    # Формируем список ответов
    lot_trade_responses = []
    for record in trading_records:
        trader_id = record['trader_id']
        trader_info = trader_infos.get(trader_id, {'full_name': 'Unknown', 'rating': 0})
        avatar_url = f"{url}/static/img/userpic/profile/{trader_id}.jpg"
        username = trader_info.get('username', 'Unknown')
        rating = trader_info.get('rating', 0)
        price = record['price'] if pro == 1 else 0
        response = LotTradeResponse(
            avatar_url=avatar_url,
            rating=rating,
            username=username,
            price=price,
            trader_id=trader_id
        )
        lot_trade_responses.append(response)
    print(lot_trade_responses)
    return lot_trade_responses


@api_router.get("/get_chat_info")
async def get_name(user_id: int):
    fields = ['username']
    user_info = await info(user_id, fields)
    name = user_info['username']
    print (name)
    return {"username": str(name)}

@api_router.get("/transaction", response_model=TransactionResponseModel)
async def get_transaction(tg_id: int = Query(...), option: int = Query(...)):
    async with aiosqlite.connect(DB_PATH) as db:
        # Получаем карты пользователя
        cursor = await db.execute(
            "SELECT id, number, system, logo FROM user_cards WHERE tg_id = ?",
            (tg_id,)
        )
        rows = await cursor.fetchall()
        cards = []
        for row in rows:
            card = {
                'id': row[0],
                'number': row[1],
                'system': row[2],
                'logo': row[3]
            }
            cards.append(card)

        # Получаем баланс пользователя
        cursor = await db.execute(
            "SELECT ballance FROM wallet_rub WHERE tg_id = ?",
            (tg_id,)
        )
        balance_row = await cursor.fetchone()
        if not balance_row:
            raise HTTPException(status_code=404, detail="User not found")
        balance = balance_row[0]
    
    return {"cards": cards, "balance": balance}

@api_router.post("/add_card", response_model=Dict[str, Any])
async def add_card(card: AddCardModel):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute('''
            INSERT INTO user_cards (tg_id, number, system, logo)
            VALUES (?, ?, ?, ?)
        ''', (card.tg_id, card.number, card.system, card.logo))
        await db.commit()
    return {"message": "Card added successfully", "status": "success"}

@api_router.delete("/delete_card/{card_id}", response_model=Dict[str, Any])
async def delete_card(card_id: int, tg_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            "SELECT id FROM user_cards WHERE id = ? AND tg_id = ?",
            (card_id, tg_id)
        )
        row = await cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Card not found")
        await db.execute(
            "DELETE FROM user_cards WHERE id = ?",
            (card_id,)
        )
        await db.commit()
    return {"message": "Card deleted successfully", "status": "success"}

@api_router.post("/wallet_ask", response_model=Dict[str, Any])
async def wallet_ask(data: WalletAskModel):
    print(data)
    trade = 0
    if data.action == 2 and data.lot_id is not None:
        trade = 1

    print(data)
    try:
        amount = float(data.amount)
    except ValueError:
        return {"message": "Invalid amount format", "status": "error"}
    
    if trade == 0:
        result = await do_balance_operation(data.tg_id, amount, data.action)

    if data.action == 2 and data.lot_id is not None:
        result = await do_balance_operation(data.tg_id, amount, 1)
        print('MAKE OFFER, LOT_ID:', data.lot_id)
        await make_offer(data.lot_id, data.tg_id, data.price, data.message)
    
    return result

@api_router.get("/settings", response_model=Settings)
async def settings_route(tg_id: int = Query(...)):
    return await get_user_settings(tg_id)


@api_router.post("/set_number")
async def set_number_route(data: PhoneUpdate):
    await update_phone(data.tg_id, data.phone)
    return {"status": "success"}


@api_router.post("/set_email")
async def set_email_route(data: EmailUpdate):
    await update_email(data.tg_id, data.email)
    return {"status": "success"}

@api_router.get("/notifications")
async def notifications_route(tg_id: int = Query(...)):
    return await get_user_notifications(tg_id)

@api_router.post("/notify_switch")
async def notify_switch_route(data: NotifySwitch):
    await switch_notification(data.tg_id, data.number, data.value)
    return {"status": "success"}

@api_router.get("/statistic", response_model=Statistic)
async def statistic_route(tg_id: int = Query(...)):
    return await get_statistic(tg_id)

@api_router.get("/profile_view", response_model=ProfileViewResponse)
async def profile_view_route(tg_id: int = Query(...)):
    return await get_profile_view(tg_id)

@api_router.post("/set_rating", response_model=SetRatingResponse)
async def set_rating_route(data: SetRatingRequest):
    return await set_rating(data)

# Роут для загрузки медиа: /temp_media
@api_router.post("/temp_media")
async def upload_temp_media(tg_id: int = Form(...), media: UploadFile = File(...)):
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    filename = f"{tg_id}_{timestamp}_{media.filename}"
    file_path = os.path.join(TEMP_MEDIA_DIR, filename)
    with open(file_path, "wb") as f:
        content = await media.read()
        f.write(content)
    created_at = datetime.utcnow().isoformat()
    async with aiosqlite.connect(TEMP_DB_PATH) as db:
        await db.execute(
            "INSERT INTO temp_media (tg_id, file_path, created_at) VALUES (?, ?, ?)",
            (tg_id, filename, created_at)
        )
        await db.commit()
    return {"status": "success"}

# Роут для опроса загруженных медиа: /wait_media
@api_router.get("/wait_media")
async def wait_media(tg_id: int = Query(...)):
    async with aiosqlite.connect(TEMP_DB_PATH) as db:
        async with db.execute("SELECT id, file_path FROM temp_media WHERE tg_id = ?", (tg_id,)) as cursor:
            rows = await cursor.fetchall()
            media_list = []
            for row in rows:
                media_id, file_path = row
                media_url = f"{BASE_API_URL}/static/img/temp_media/{file_path}"
                media_list.append({"id": media_id, "url": media_url})
            return media_list

# роут для проверки уже загруженных медиа: /check_temp_media
@api_router.get("/check_temp_media")
async def check_temp_media(tg_id: int = Query(...)):
    async with aiosqlite.connect(TEMP_DB_PATH) as db:
        async with db.execute("SELECT id, file_path FROM temp_media WHERE tg_id = ?", (tg_id,)) as cursor:
            rows = await cursor.fetchall()
            media_list = []
            for row in rows:
                media_id, file_path = row
                media_url = f"{BASE_API_URL}/static/img/temp_media/{file_path}"
                media_list.append({"id": media_id, "url": media_url})
            return media_list

# Роут для удаления временного медиа: /temp_delete
@api_router.post("/temp_delete")
async def delete_temp_media(data: TempDeleteRequest):
    async with aiosqlite.connect(TEMP_DB_PATH) as db:
        async with db.execute("SELECT file_path FROM temp_media WHERE id = ? AND tg_id = ?", (data.media_id, data.tg_id)) as cursor:
            row = await cursor.fetchone()
            if row:
                file_path = row[0]
                await db.execute("DELETE FROM temp_media WHERE id = ? AND tg_id = ?", (data.media_id, data.tg_id))
                await db.commit()
                full_path = os.path.join(TEMP_MEDIA_DIR, file_path)
                if os.path.exists(full_path):
                    os.remove(full_path)
                return {"status": "success"}
            else:
                raise HTTPException(status_code=404, detail="Media not found")
            

@api_router.post("/change_username")
async def change_username(request: ChangeUsernameRequest):
    try:
        await change_username_in_db(request.tg_id, request.username)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@api_router.post("/phone")
async def phone_endpoint(request: PhoneRequest):
    print(f"tg_id: {request.tg_id}, phone: {request.phone}")
    
    try:
        status = await get_confirmation_number(request.phone)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
    return {"status": status}

async def get_confirmation_number(user_phone: str) -> str:
    zvonok_api_url = "https://zvonok.com/manager/cabapi_external/api/v1/phones/confirm/"
    payload = {
        "public_key": "f566ad5a097649dfa7826837027f7dea",
        "phone": user_phone,
        "campaign_id": "814789886"
    }
    async with httpx.AsyncClient() as client:
        response = await client.post(zvonok_api_url, data=payload)
    data = response.json()
    if data.get("status") == "ok":
        return data.get("data", {}).get("status")
    raise HTTPException(status_code=500, detail=data)

@api_router.post("/phone_check")
async def phone_check(request: PhoneCheckRequest):
    phone = request.phone
    print("Received phone:", phone)
    if phone.startswith("+"):
        phone = phone[1:]
    print("Processed phone:", phone)
    url = "https://zvonok.com/manager/cabapi_external/api/v1/phones/calls_by_phone/"
    params = {
        "campaign_id": "814789886",
        "phone": f"+{phone}",
        "public_key": "f566ad5a097649dfa7826837027f7dea"
    }
    print("Sending request to:", url, "with params:", params)
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)
    print("Response status code:", response.status_code)
    if response.status_code != 200:
        print("Error response text:", response.text)
        raise HTTPException(status_code=response.status_code, detail=response.text)
    data = response.json()
    
    if isinstance(data, dict) and data.get("status") == "error":
        print("Error status in response:", data.get("data"))
        raise HTTPException(status_code=400, detail=data.get("data"))
    if isinstance(data, list):
        for item in data:
            print("Processing item:", item)
            if item.get("status") == "pincode_ok":
                print("Status 'pincode_ok' found. Verifying user.")
                tg_id = await verify_user(request.tg_id, str(phone))
                print("verify_user returned tg_id:", tg_id)
                return {"status": 200, "tg_id": tg_id}
        for item in data:
            if item.get("status") == "in_process":
                print("Status 'in_process' found.")
                raise HTTPException(status_code=300, detail="Номер еще не подтвержден")
        print("No valid status found in response list.")
        raise HTTPException(status_code=400, detail="Номер не подтвержден")
    print("Unexpected response format.")
    raise HTTPException(status_code=400, detail="Неизвестный ответ от Zvonok API")

@api_router.get("/check_pro")
async def check_pro(userId: int = Query(..., description="ID пользователя")):
    print(userId)
    pro = await pro_check(userId)
    return pro

@api_router.post("/change_bet")
async def change_bet(data: ChangeBetRequest):
    print("Получен запрос на изменение ставки:")
    await change_offer(data.tg_id, data.lot_id, data.amount)
    return {"status": "success"}


@api_router.post("/auto_bet")
async def auto_bet(data: AutoBetRequest):
    print("Получен запрос на запуск автоставки:")
    await create_auto_bet(data.tg_id, data.lot_id, data.auto_step, data.auto_limit)
    print(f"tg_id: {data.tg_id}, lot_id: {data.lot_id}, auto_step: {data.auto_step}, auto_limit: {data.auto_limit}")
    return {"status": "success"}

@api_router.get("/chat_btn")
async def chat_btn(lotId: int, userId: int):
    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT tg_id FROM lots WHERE id = ?", (lotId,)) as cursor:
            row = await cursor.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail="Lot not found")
            tg_id = row[0]
            print('TG_ID', tg_id, 'USER_ID', userId)
            return 1 if tg_id == userId else 0
        

@api_router.post("/pro_buy")
async def pro_buy(userId: str = Form(...)):
    await set_pro(int(userId))
    return 1

@api_router.post("/choose_winner", response_model=ChooseWinnerResponse)
async def choose_winner(req: ChooseWinnerRequest):
    print(req)
    await change_status(int(req.lotId), 11)
    await set_winner(int(req.userId2), int(req.lotId))
    new_lot_status = "11"  
    return ChooseWinnerResponse(lotStatus=new_lot_status)

@api_router.post("/wallet_chat", response_model=WalletChatResponse)
async def wallet_chat(req: WalletChatRequest):
    print("Получено в /wallet_chat:", req)
    wallet_data = await get_wallet_data(req.tg_id)
    price = int(await get_trade_price(req.tg_id, req.lotId))
    if req.action is not None:
        if req.action == 1:
            await do_balance_operation(req.tg_id, price, 3)
            await change_status(req.lotId, 6)
            await set_winner(req.tg_id, req.lotId, 1)
            return WalletChatResponse(balance=wallet_data['balance'], frozen_funds=wallet_data['frozen_funds'], is_first=wallet_data['is_first'], price=price, lotStatus="6")
    else:
        return WalletChatResponse(balance=wallet_data['balance'], frozen_funds=wallet_data['frozen_funds'], is_first=wallet_data['is_first'], price=price)

@api_router.post("/send_prove", response_model=SendProveResponse)
async def send_prove(req: SendProveRequest):
    print("Received /send_prove:", req)
    try:
        img_data = base64.b64decode(req.photo)
        await change_status(req.lotId, 7)
        path = f"static/img/lots/prove/{req.lotId}.jpg"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(img_data)
        return SendProveResponse(lotStatus="7")
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid photo data")

@api_router.post("/lot_recieve", response_model=LotRecieveResponse)
async def lot_recieve(req: LotRecieveRequest):
    price = int(await get_trade_price(req.userId, req.lotId))
    await do_balance_operation(req.userId2, price, 2)
    await change_status(req.lotId, 8)
    print("Received /lot_recieve:", req)
    return LotRecieveResponse(lotStatus="8")
