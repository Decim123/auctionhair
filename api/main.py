from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.api import api_router 
from admin.routes import admin_router
from fastapi.staticfiles import StaticFiles

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене заменить "*" на список разрешенных доменов
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# папка для статических файлов
app.mount("/static", StaticFiles(directory="static"), name="static")

# роутеры для API и админ панели
app.include_router(api_router, prefix="/api", tags=["API"])
app.include_router(admin_router, prefix="/admin", tags=["Admin"])
