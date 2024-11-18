from pydantic import BaseModel
from typing import Optional
from typing import List

# Модель для получения информации о пользователе
class UserRequest(BaseModel):
    tg_id: int
    function: str

# Модель для запроса информации о пользователе
class InfoRequest(BaseModel):
    tg_id: int
    fields: List[str]

# Модель для старта с Telegram
class TgStart(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    full_name: Optional[str] = None
    username: Optional[str] = None
    user_id: int
    is_premium: Optional[bool] = None
    language_code: Optional[str] = None

# Модель для создания работника
class InitWorker(BaseModel):
    tg_id: int
    username: str
    full_name: Optional[str] = None
    key: str

# Модель ключа
class KeyModel(BaseModel):
    key: str