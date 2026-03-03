"""
unifind_django/wsgi.py

WSGI config for the UniFind Django backend.
This is the entry point when a real web server (like gunicorn or nginx)
runs the app. Since we're just running `python manage.py runserver`
like civilized people, this file basically just sits here looking official.
"""

import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'unifind_django.settings')
application = get_wsgi_application()
