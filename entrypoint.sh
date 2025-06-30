#!/bin/sh
set -e

echo "Applying migrations ..."
python manage.py migrate --noinput

if [ "${MIGRATE_AND_CREATE_USER_ON_STARTUP:-false}" = "true" ]; then
  echo "Creating superuser (idempotent) ..."
  python manage.py createsuperuser --noinput \
    --username "$DJANGO_SU_NAME" \
    --email "$DJANGO_SU_EMAIL" \
    || true     
fi

echo "Starting gunicorn ..."
exec "$@"
