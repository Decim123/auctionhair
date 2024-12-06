import json
from aiogram import Router, Bot, types
from aiogram.filters import Command, CommandStart
from aiogram.types import Message, CallbackQuery, InlineKeyboardMarkup, InlineKeyboardButton
from services.services import *
from keyboards.keyboard import *
import aiohttp

router = Router()
user_states = {}
user_photos = {}

async def send_lot_to_api(bot: Bot, lot_id, photos):
    url = f'{api_url}create_lot_from_bot'
    data = {
        'lot_id': str(lot_id),
    }
    form = aiohttp.FormData()
    for key, value in data.items():
        form.add_field(key, value)
    for idx, file_id in enumerate(photos):
        file = await bot.get_file(file_id)
        file_bytes = await bot.download_file(file.file_path)
        form.add_field(
            name='files',
            value=file_bytes.getvalue(),
            filename=f'photo_{idx}.jpg',
            content_type='image/jpeg'
        )
    async with aiohttp.ClientSession() as session:
        async with session.post(url, data=form) as resp:
            if resp.status != 200:
                raise Exception(f'API returned status code {resp.status}')
            resp_data = await resp.text()
            print(resp_data)

@router.message(CommandStart())
async def start_command(message: Message, bot: Bot):
    user_id = message.from_user.id
    user_photos_data = await bot.get_user_profile_photos(user_id=user_id, limit=1)
    if user_photos_data.total_count > 0:
        photo = user_photos_data.photos[0][-1]
        file = await bot.get_file(photo.file_id)
        file_path = f"../api/static/img/userpic/{user_id}.jpg"
        await bot.download_file(file.file_path, destination=file_path)
    user_data = {
        'first_name': message.from_user.first_name,
        'last_name': message.from_user.last_name,
        'full_name': message.from_user.full_name,
        'username': message.from_user.username,
        'user_id': message.from_user.id,
        'is_premium': message.from_user.is_premium,
        'language_code': message.from_user.language_code,
    }
    API_URL = f'{api_url}tg_start'
    async with aiohttp.ClientSession() as session:
        async with session.post(API_URL, json=user_data) as resp:
            if resp.status == 200:
                api_response = await resp.json()
                print("Данные успешно отправлены на API:", api_response)
            else:
                print(f"Ошибка при отправке данных на API: {resp.status}")
                error_text = await resp.text()
                print(f"Тело ответа с ошибкой: {error_text}")
    caption = f'''First name: {message.from_user.first_name}
Last name: {message.from_user.last_name}
Full name: {message.from_user.full_name}
Username: {message.from_user.username}
User ID: {message.from_user.id}
Is Premium: {message.from_user.is_premium}
Language Code: {message.from_user.language_code}
'''
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Auction", web_app=types.WebAppInfo(url=app_url))
        ]
    ])  
    file_path = "img/vite.png"
    await message.answer_photo(
        types.FSInputFile(file_path),
        caption=caption,
        reply_markup=inline_kb
    )

@router.message(Command(commands='admin'))
async def process_admin_command(message: Message):
    if await check_admin(int(message.from_user.id)) == 1:
        await message.answer("Админ панель", reply_markup=admin_kb())
    else:
        await message.answer("?")

@router.message()
async def process_user_message(message: Message, bot: Bot):
    tg_id = int(message.from_user.id)
    print('ДАННЫЕ ПОЛЬЗОВАТЕЛЯ 2', tg_id)
    if tg_id in user_states:
        lot_id = user_states[tg_id]
        print('ДАННЫЕ ЛОТА', lot_id)
        if message.photo:
            if tg_id not in user_photos:
                user_photos[tg_id] = []
            largest_photo = message.photo[-1]
            file_id = largest_photo.file_id
            user_photos[tg_id].append(file_id)
            await message.answer(
                'Изображения приняты, вы можете добавить еще изображения или нажать создать, чтобы закончить создание лота',
                reply_markup=create_lot_kb()
            )
        else:
            await message.answer(
                'Пожалуйста, отправьте фотографии или нажмите "Создать", чтобы завершить создание лота.',
                reply_markup=create_lot_kb()
            )
    elif await check_key_via_api(message.text) == 1:
        username = message.from_user.username
        full_name = message.from_user.full_name
        key = message.text
        try:
            await add_worker_via_api(tg_id, username, full_name, key)
            await message.answer('Доступ получен\nУстановите логин и пароль', reply_markup=admin_auth_kb(tg_id))
        except:
            await message.answer('Ошибка')
    else:
        await message.answer('?', reply_markup=app_kb())

@router.callback_query()
async def process_callback(callback_query: CallbackQuery, bot: Bot):
    tg_id = int(callback_query.from_user.id)
    if callback_query.data == 'create_lot':
        if tg_id in user_photos and tg_id in user_states:
            photos = user_photos[tg_id]
            lot_id = user_states[tg_id]
            try:
                await send_lot_to_api(bot, lot_id, photos)
                await bot.send_message(tg_id, 'Лот успешно создан!', reply_markup=app_kb())
                del user_photos[tg_id]
                del user_states[tg_id]
            except Exception as e:
                await bot.send_message(tg_id, f'Ошибка при создании лота: {e}', reply_markup=app_kb())
        else:
            await bot.send_message(tg_id, 'Нет данных для создания лота.', reply_markup=app_kb())
    else:
        data = callback_query.data
        parts = data.split('_')
        lot_id = parts[4]
        user_states[tg_id] = lot_id
        print("Переданный lot_id:", lot_id)
        API_URL = f'{api_url}get_lot_without_img'

        async with aiohttp.ClientSession() as session:
            async with session.post(API_URL, json={"lot_id_withot_img": int(lot_id)}) as resp:
                if resp.status == 200:
                    response_data = await resp.json()
                    print('ДАННЫЕ ПОЛЬЗОВАТЕЛЯ 1', tg_id)
                    print('ДАННЫЕ АУКЦИОНА 1', response_data)
                    auction_data = response_data.get('data', [])
                    if auction_data:
                        auction_info = f"""
Данные аукциона:
- Длина: {auction_data[3]}
- Натуральный цвет: {auction_data[4]}
- Текущий цвет: {auction_data[5]}
- Тип волос: {auction_data[6]}
- Возраст: {auction_data[7]}
- Вес: {auction_data[8]}
- Описание: {auction_data[9]}
- Цена: {auction_data[10]}
- Период: {auction_data[11]}
- Шаг: {auction_data[12]}

Чтобы добавить фото к этому аукциону, просто отправте его в чат.
                        """
                        await callback_query.message.edit_text(auction_info)
                    else:
                        await callback_query.message.edit_text('Данные аукциона не найдены.')
                else:
                    print(f"Ошибка при отправке данных на API: {resp.status}")
                    error_text = await resp.text()
                    print(f"Тело ответа с ошибкой: {error_text}")
                    await callback_query.message.edit_text('Ошибка при получении данных аукциона.')
        await callback_query.answer()
