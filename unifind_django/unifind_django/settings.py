"""
unifind_django/settings.py

Django settings for the UniFind backend.

This is the sacred configuration file. Touch it wrong and everything breaks.
You have been warned. Seriously. Don't move CORS_ALLOW_ALL_ORIGINS.
"""

from pathlib import Path

# ============================================================
# BASE CONFIGURATION — the holy trinity of Django settings
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

# Keep this secret. If this ends up on GitHub I will personally
# come to your house and flip your monitor upside down.
SECRET_KEY = 'CHANGE-THIS-BEFORE-DEMO-OR-SO-HELP-YOU'

# Set to False for anything that isn't your laptop.
# We are NOT deploying this. It lives and dies on localhost.
DEBUG = True

ALLOWED_HOSTS = ['localhost', '127.0.0.1', '10.0.2.2']
# ^ 10.0.2.2 is what the Android emulator calls your machine's localhost.
# If you're on a physical device, add your machine's local IP here too.
# Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to find it.


# ============================================================
# INSTALLED APPS — the gang's all here
# ============================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',           # DRF — the API machinery
    'rest_framework.authtoken', # Token auth — how Flutter proves who it is
    'corsheaders',              # CORS — lets Flutter actually talk to us
    'api',                      # Our app — the whole reason this exists
]


# ============================================================
# MIDDLEWARE — the gauntlet every request runs through
# ============================================================

MIDDLEWARE = [
    # CORS MUST be first. If you move this I promise things will break
    # and you will spend 3 hours debugging "why does Flutter get 403s"
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]


# ============================================================
# URL CONFIGURATION
# ============================================================

ROOT_URLCONF = 'unifind_django.urls'


# ============================================================
# TEMPLATES — we barely use these since Flutter is the UI
# ============================================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'unifind_django.wsgi.application'


# ============================================================
# DATABASE — the cPanel MySQL connection
#
# Go to your cPanel account → MySQL Databases.
# You'll find the database name, username, and host there.
# The host is usually 'localhost' if Django is running ON the
# same cPanel server, OR a hostname like 'yourdomain.com' if
# connecting remotely from your laptop.
#
# For local development with XAMPP: host = 'localhost',
# user = 'root', password = '', port = 3306
# ============================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME':     'unifind_db',
        'USER':     'root',
        'PASSWORD': '',          # XAMPP default has no password
        'HOST':     'localhost',
        'PORT':     '3306',
        'OPTIONS': {
            'charset': 'utf8mb4',
        },
    }
}


# ============================================================
# CUSTOM AUTH — we're using our own User model
# ============================================================

AUTH_USER_MODEL = 'api.User'


# ============================================================
# DJANGO REST FRAMEWORK — the API config
# ============================================================

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        # By default, every endpoint requires a valid token.
        # Endpoints that need to be public (login, register) override this
        # with @permission_classes([AllowAny]).
        'rest_framework.permissions.IsAuthenticated',
    ],
}


# ============================================================
# CORS — Cross-Origin Resource Sharing
#
# Flutter running on an Android emulator is technically a
# "different origin" than our Django server. Without this,
# every request gets blocked by the browser/WebView security
# policies. We allow all origins here because we're on localhost
# and if someone is trying to CORS-attack our demo project
# they need to go outside and touch grass.
# ============================================================

CORS_ALLOW_ALL_ORIGINS = True


# ============================================================
# INTERNATIONALIZATION — we're just in New Jersey
# ============================================================

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'America/New_York'
USE_I18N = True
USE_TZ = True


# ============================================================
# STATIC & MEDIA FILES
# ============================================================

STATIC_URL = 'static/'

import os
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
