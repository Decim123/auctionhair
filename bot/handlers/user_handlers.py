from aiogram import Router, F, Bot, types
from aiogram.filters import Command, CommandStart
from aiogram.types import Message, CallbackQuery
from services.services import *
from keyboards.keyboard import *
router = Router()
user_states = {}
url = 'https://306e-81-25-56-81.ngrok-free.app/'

@router.message(CommandStart())
async def start_command(message: Message, bot: Bot):
    
    path_to_photo = "img/vite.png"
    caption = f'''First name: {message.from_user.first_name}
Last name: {message.from_user.last_name}
Full name: {message.from_user.full_name}
Username: {message.from_user.username}
User ID: {message.from_user.id}
Is Bot: {message.from_user.is_bot}
Is Premium: {message.from_user.is_premium}
Language Code: {message.from_user.language_code}
Added to Attachment Menu: {message.from_user.added_to_attachment_menu}
Can Join Groups: {message.from_user.can_join_groups}
Can Read All Group Messages: {message.from_user.can_read_all_group_messages}
Supports Inline Queries: {message.from_user.supports_inline_queries}
'''

    
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Auction", web_app=types.WebAppInfo(url=url))
        ]
    ])  

    await message.answer_photo(
        types.FSInputFile(path=path_to_photo),
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