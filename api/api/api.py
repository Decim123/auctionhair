from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from .models import *
from db import *
import shutil
import os

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

    upload_directory = "../database/img/userpic/verify"
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

@api_router.post("/add_worker")
async def create_worker(worker: InitWorker):
    try:
        access_level = await get_access_level(worker.key)
        await add_worker_if_not_exists(worker.tg_id, worker.username, worker.full_name, access_level)
        return {"message": "Worker added successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))