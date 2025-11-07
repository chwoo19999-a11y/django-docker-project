# 빌드 스테이지
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 빌드에 필요한 시스템 패키지
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 런타임 스테이지
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 런타임 라이브러리만 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# 빌드 스테이지에서 Python 패키지 복사
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 비root 사용자 생성
RUN useradd -m -u 10000 django && \
    chown -R django:django /app

# 코드 복사
COPY --chown=django:django . .

# 정적 파일 수집 (manage.py는 /app에 있음)
RUN python manage.py collectstatic --noinput

USER django

EXPOSE 8000

# Gunicorn으로 실행
CMD ["gunicorn", "app.django_practice.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--threads", "2", \
     "--timeout", "60", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]