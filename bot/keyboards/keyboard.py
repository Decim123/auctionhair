from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from services.services import admin_url
from aiogram import types
from services.services import *

def admin_auth_kb(tg_id):
    url = f'{admin_url}set_lp?tg_id={tg_id}'
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Установить", url=url)
        ]
    ])
    return inline_kb

def admin_kb():
    url = f'{admin_url}login'
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Админ панель", url=url)
        ]
    ])
    return inline_kb

def create_lot_kb():
    keyboard = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text='Создать', callback_data='create_lot')
        ]
    ])
    return keyboard

def app_kb():
    inline_kb = InlineKeyboardMarkup(inline_keyboard=[
        [
            InlineKeyboardButton(text="Auction", web_app=types.WebAppInfo(url=app_url))
        ]
    ])
    return inline_kb  