# main.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

from db import *

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене заменить "*" на список разрешенных доменов
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
