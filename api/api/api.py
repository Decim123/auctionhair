import math
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Query, Request, UploadFile, File, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from .models import *
from db import *
import shutil
import os
import requests
from PIL import Image
from io import BytesIO

TELEGRAM_BOT_TOKEN = '8138748896:AAGz_PbbiXxPZLT1POm2Si586iWlTFCN3Qk'
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

# объект роутера для API
api_router = APIRouter()

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
async def wallet_data(tg_id: int = Query(..., description="Telegram ID пользователя")):
    data = await get_wallet_data(tg_id) 
    if data:
        return data
    else:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
@api_router.get("/transaction")
async def get_transaction_data(tg_id: int, option: int):
    data = await get_wallet_data(tg_id)
    balance = math.floor(data['balance'])
    data = {
        'баланс': balance,
        'карты': [
            {
                'id': 1,
                'logo': 'sber',
                'number': '1234567812345678',
                'system': 'Visa'
            },
            {
                'id': 2,
                'logo': 'tbank',
                'number': '8765432187654321',
                'system': 'МИР'
            }
        ]
    }
    return data

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

@api_router.post("/get_auctions")
async def get_auctions(request: GetAuctionsRequest):
    tg_id = request.tg_id
    auctions = await get_user_auctions(tg_id)
    print(auctions)
    return [auction.dict() for auction in auctions]

@api_router.get("/get_auction_photo", response_model=List[str])
async def get_auction_photo(id: int = Query(..., description="Auction ID")):
    # Определение местоположения текущего файла
    current_file_path = os.path.abspath(__file__)
    current_dir = os.path.dirname(current_file_path)
    
    # Построение пути к целевой директории относительно текущего файла
    relative_directory = "../static/img/lots/auctions/"
    directory = os.path.abspath(os.path.join(current_dir, relative_directory))
    
    # Вывод полного пути для отладки
    print(f"Текущий рабочий каталог: {os.getcwd()}")
    print(f"Полный путь директории для изображений: {directory}")
    
    # Проверка существования директории
    if not os.path.exists(directory):
        raise HTTPException(status_code=404, detail="Directory not found")
    
    try:
        # Получение списка файлов в директории
        files = os.listdir(directory)
    except OSError as e:
        raise HTTPException(status_code=500, detail=f"Error accessing directory: {e}")
    
    # Фильтрация файлов по условиям
    matching_files = [
        file_name for file_name in files
        if os.path.isfile(os.path.join(directory, file_name)) and
           file_name.startswith(f"{id}_") and
           os.path.splitext(file_name)[1].lower() in ['.png', '.jpg']
    ]
    
    # Вывод найденных файлов для отладки
    print(f"Найденные файлы для аукциона {id}: {matching_files}")
    
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
    # Создаем экземпляр модели LotData
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
    # Формируем сообщение для отправки пользователю
    message_text = (
        f"Чтобы завершить создание, прикрепите изображения"
    )

    # Формируем данные для инлайн-кнопки
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
    for idx, photo in enumerate(files):
        contents = await photo.read()
        file_name = f"{new_lot_id}_{idx+1}.jpg"
        await compress_and_save_image(contents, file_name)
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