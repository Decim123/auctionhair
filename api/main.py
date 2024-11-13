# main.py

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List
from fastapi.staticfiles import StaticFiles
import aiohttp
import json
from db import *
import shutil

BOT_TOKEN = '8138748896:AAGz_PbbiXxPZLT1POm2Si586iWlTFCN3Qk'

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене заменить "*" на список разрешенных доменов
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount(
    "/img",
    StaticFiles(directory=os.path.abspath("../database/img"), check_dir=False),
    name="photos"
)
class UserRequest(BaseModel):
    tg_id: int
    function: str

@app.post('/user_info')
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

class InfoRequest(BaseModel):
    tg_id: int
    fields: List[str]


@app.post('/info')
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

class TgStart(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    full_name: Optional[str] = None
    username: Optional[str] = None
    user_id: int
    is_premium: Optional[bool] = None
    language_code: Optional[str] = None

@app.post('/tg_start')
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

@app.post("/verify_try")
async def verify_try(
    tg_id: str = Form(...),
    name_1: str = Form(...),
    name_2: str = Form(...),
    name_3: str = Form(...),
    image: UploadFile = File(...)
):
    # Распечатаем полученную информацию
    print(f"tg_id: {tg_id}")
    print(f"name_1: {name_1}")
    print(f"name_2: {name_2}")
    print(f"name_3: {name_3}")
    file_type = str(image.filename).split('.')[1]
    # Сохраним изображение
    upload_directory = "../database/img/userpic/verify"
    os.makedirs(upload_directory, exist_ok=True)
    file_location = os.path.join(upload_directory, f'{tg_id}.{file_type}')

    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    return {"status": "success", "message": "Data received and image saved."}