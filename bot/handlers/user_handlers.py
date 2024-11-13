from aiogram import Router, F, Bot, types
from aiogram.filters import Command, CommandStart
from aiogram.types import Message, CallbackQuery, InlineKeyboardMarkup, InlineKeyboardButton
from services.services import *
from keyboards.keyboard import *
import aiohttp  # Импортируем aiohttp для HTTP-запросов

router = Router()
user_states = {}
url = 'https://5c63-81-25-62-112.ngrok-free.app'

API_URL = 'https://dcf2-176-59-162-63.ngrok-free.app/tg_start'

@router.message(CommandStart())
async def start_command(message: Message, bot: Bot):
    user_id = message.from_user.id
    user_photos = await bot.get_user_profile_photos(user_id=user_id, limit=1)
    
    if user_photos.total_count > 0:
        photo = user_photos.photos[0][-1]
        file = await bot.get_file(photo.file_id)
        file_path = f"../database/img/userpic/{user_id}.jpg"
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
            InlineKeyboardButton(text="Auction", web_app=types.WebAppInfo(url=url))
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
    tg_id = message.from_user.id
    await message.answer("Введите пароль:")

@router.message()
async def process_user_message(message: Message, bot: Bot):
    tg_id = message.from_user.id
    await message.answer('?')

