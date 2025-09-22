from pydantic import BaseModel
from typing import Optional
from typing import List

# Модель для логина
class LoginRequest(BaseModel):
    login: str
    password: str

# Модель для возвращаемого токена
class TokenResponse(BaseModel):
    access_token: str
    token_type: str

# Модель для создания нового пользователя
class SetLP(BaseModel):
    tg_id: int
    login: str
    password: str