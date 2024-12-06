from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from api.api import api_router
from admin.routes import admin_router

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры для API и админ панели
app.include_router(api_router, prefix="/api", tags=["API"])
app.include_router(admin_router, prefix="/admin", tags=["Admin"])

# Обслуживание статической папки для других файлов
app.mount("/static", StaticFiles(directory="static"), name="static")

# Обслуживание статических файлов (Flutter-приложения)
app.mount("/", StaticFiles(directory="web", html=True), name="web")

# Обработка OPTIONS запросов
@app.options("/{rest_of_path:path}")
async def preflight_handler(rest_of_path: str):
    return Response(status_code=200)
