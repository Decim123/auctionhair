from fastapi import APIRouter, Request, Form, Depends, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta
from db import *
from admin.models import *
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from fastapi import Cookie

admin_router = APIRouter()

templates = Jinja2Templates(directory="admin/templates")

SECRET_KEY = "123123m&m's"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def create_access_token(data: dict, expires_delta: timedelta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)):
    to_encode = data.copy()
    expire = datetime.utcnow() + expires_delta
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# Модели Pydantic
class LoginRequest(BaseModel):
    login: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

class SetLP(BaseModel):
    tg_id: int
    login: str
    password: str

@admin_router.get("/set_lp", response_class=HTMLResponse)
async def set_lp(request: Request, tg_id: int):
    if await check_worker_exists(tg_id) == 1:
        return templates.TemplateResponse("auth/set_lp.html", {"request": request, "tg_id": tg_id})
    else:
        return {'у вас нет доступа к этой странице'}

@admin_router.post("/create_lp")
async def create_lp(
    request: Request,
    tg_id: int = Form(...),
    login: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
):
    if password != confirm_password:
        return {"error": "Пароли не совпадают."}

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    set_lp = SetLP(tg_id=tg_id, login=login, password=hashed_password.decode('utf-8'))
    await update_worker_login_password(set_lp.tg_id, set_lp.login, set_lp.password)
    return templates.TemplateResponse("auth/login.html", {"request": request})

@admin_router.get("/login", response_class=HTMLResponse)
async def login_form(request: Request):
    return templates.TemplateResponse("auth/login.html", {"request": request})

@admin_router.post("/login", response_model=TokenResponse)
async def login(
    request: Request,
    login: str = Form(...),
    password: str = Form(...),
):
    worker = await get_worker_by_login(login)
    if not worker or not verify_password(password, worker['password']):
        raise HTTPException(status_code=400, detail="Неверное имя пользователя или пароль")

    access_token = create_access_token(data={"sub": login})

    response = RedirectResponse(url="/admin/main")
    response.set_cookie(key="access_token", value=access_token, httponly=True)
    return response

@admin_router.get("/main", response_class=HTMLResponse)
async def main(request: Request, access_token: str = Cookie(None)):
    if not access_token:
        raise HTTPException(status_code=401, detail="Токен отсутствует")

    try:
        payload = jwt.decode(access_token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")

        if not username:
            raise HTTPException(status_code=403, detail="Invalid token")

        worker = await get_worker_by_login(username)
        if not worker:
            raise HTTPException(status_code=403, detail="Пользователь не найден")

        return templates.TemplateResponse("main/main.html", {"request": request, "user": worker})

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")



@admin_router.get("/logout")
async def logout(request: Request):
    response = RedirectResponse(url="/admin/login")
    response.delete_cookie("access_token")
    return response
