# Используем официальный образ Python
FROM python:3.9-slim

# Устанавливаем необходимые пакеты
RUN apt-get update && apt-get install -y \
    supervisor \
 && rm -rf /var/lib/apt/lists/*

# Создаем директории для приложения
WORKDIR /app

# Копируем FastAPI приложение
COPY api /app/api

# Копируем бота
COPY bot /app/bot

# Копируем базу данных (если требуется)
COPY database /app/database
COPY db_creator.py /app/db_creator.py

# Устанавливаем зависимости Python
COPY api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Копируем конфигурацию supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Экспонируем порт 8000
EXPOSE 8000

# Запускаем supervisord
CMD ["/usr/bin/supervisord"]
