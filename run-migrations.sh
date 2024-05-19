!/bin/sh

echo "Collect static assets"
python manage.py collectstatic --no-input

echo "Apply database migrations"
python manage.py migrate

exit 0