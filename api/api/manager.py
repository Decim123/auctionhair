import asyncio
import aiosqlite
from datetime import datetime
from zoneinfo import ZoneInfo
import os
from db import DB_PATH, current_time, auto_bet


async def check_and_update_lots():
    while True:
        try:
            async with aiosqlite.connect(DB_PATH) as db:
                await db.execute('''
                    UPDATE lots
                    SET status = 4
                    WHERE lot_type = 'auction'
                      AND status != 4
                      AND datetime(period) < datetime(?)
                ''', (current_time.isoformat(),))
                await db.commit()
        except Exception as e:
            print("Ошибка при обновлении статуса лотов:", e)

        try:
            await auto_bet()
        except Exception as e:
            print("Ошибка при автоматической ставке:", e)
            
        await asyncio.sleep(100)
