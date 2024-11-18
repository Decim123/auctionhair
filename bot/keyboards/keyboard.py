from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from services.services import admin_url
from aiogram import types

def admin_auth_kb(tg_id):
    url = f'{admin_url}set_lp?tg_id={tg_id}'
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Установить", url=url)
        ]
    ])
    return inline_kb