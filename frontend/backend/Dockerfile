# FastAPI-Backend (CallAgent) — Produktion mit Uvicorn
# Build (vom Monorepo-Root): docker build -t callagent-backend -f backend/Dockerfile backend
FROM python:3.12-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8000

# Kein --reload in Produktion
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
