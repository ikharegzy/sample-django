FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc build-essential python3-dev libpq-dev && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get purge -y build-essential python3-dev gcc && \
    rm -rf /var/lib/apt/lists/*


FROM base AS prod


COPY . .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "mysite.wsgi:application"]
