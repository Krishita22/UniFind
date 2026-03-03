#!/usr/bin/env python
"""
manage.py — Django's swiss army knife.

You'll be running this constantly:
  python manage.py runserver       ← start the backend
  python manage.py makemigrations  ← generate migration files after model changes
  python manage.py migrate         ← apply migrations to the database
  python manage.py createsuperuser ← create an admin account for /admin/

If you run `python manage.py` with no arguments it'll list every
available command. There are way more than you'd expect.
"""

import os
import sys


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'unifind_django.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Make sure it's installed and that your "
            "virtual environment is activated. If you're seeing this message "
            "and you didn't activate the venv, that's why."
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
