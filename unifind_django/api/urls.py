"""
api/urls.py

URL routing for the UniFind API.

Every path here gets prefixed with /api/ because of how it's
included in the master urls.py. So:
  register/       → http://localhost:8000/api/register/
  login/          → http://localhost:8000/api/login/
  ...etc

Flutter will hit these URLs. Make sure your Flutter teammate
knows the exact paths and expected request formats.
See the "FLUTTER API CONTRACT" section at the bottom of this file.
"""

from django.urls import path
from . import views

urlpatterns = [
    # ---- AUTH ENDPOINTS (no token required) ----

    # Create a new account. Sends verification email on success.
    # POST body: { "email": "...", "password": "...", "full_name": "..." }
    path('register/', views.register, name='register'),

    # Email verification. User clicks this link from their inbox.
    # GET params: ?token=<raw_token>&email=<email>
    path('verify-email/', views.verify_email, name='verify-email'),

    # Log in with credentials. Returns auth token on success.
    # POST body: { "email": "...", "password": "..." }
    path('login/', views.login, name='login'),

    # Resend verification email if the first one was lost/expired.
    # POST body: { "email": "..." }
    path('resend-verify/', views.resend_verification, name='resend-verify'),


    # ---- PROTECTED ENDPOINTS (token required in Authorization header) ----
    # Header format: Authorization: Token <token_value>

    # Invalidate the current auth token (log out).
    # POST, no body needed.
    path('logout/', views.logout, name='logout'),

    # Get current user's profile info.
    # GET, no body needed.
    path('me/', views.me, name='me'),
]


# ============================================================
# FLUTTER API CONTRACT
# Pass this to your Flutter teammate so they know what to call.
# ============================================================
#
# BASE URL (when running on Android emulator):
#   http://10.0.2.2:8000/api/
#
# BASE URL (when running on physical device):
#   http://<your-machine-local-IP>:8000/api/
#   Find your IP with `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
#   Example: http://192.168.1.42:8000/api/
#
# ---- REGISTER ----
# POST /api/register/
# Headers: Content-Type: application/json
# Body:    { "email": "user@montclair.edu", "password": "pass123", "full_name": "John Doe" }
# 201:     { "message": "...", "email_sent": true }
# 400:     { "error": "Only @montclair.edu email addresses are allowed." }  (or other errors)
#
# ---- VERIFY EMAIL (user clicks the link, can open in browser) ----
# GET /api/verify-email/?token=<token>&email=<email>
# 200:     { "message": "Email verified successfully!" }
# 400:     { "error": "This verification link has expired..." }
#
# ---- LOGIN ----
# POST /api/login/
# Headers: Content-Type: application/json
# Body:    { "email": "user@montclair.edu", "password": "pass123" }
# 200:     { "token": "9944b09199...", "user": { "email": ..., "full_name": ..., "is_admin": false } }
# 401:     { "error": "Invalid email or password." }
# 403:     { "error": "Please verify your email...", "can_resend": true }
#
# ---- LOGOUT ----
# POST /api/logout/
# Headers: Authorization: Token 9944b09199...
# 200:     { "message": "Logged out successfully." }
#
# ---- GET CURRENT USER ----
# GET /api/me/
# Headers: Authorization: Token 9944b09199...
# 200:     { "email": ..., "full_name": ..., "is_admin": false, "is_verified": true }
# 401:     (automatic, token invalid or missing)
#
# ---- RESEND VERIFICATION ----
# POST /api/resend-verify/
# Headers: Content-Type: application/json
# Body:    { "email": "user@montclair.edu" }
# 200:     { "message": "Verification email sent..." }
# 429:     { "error": "Please wait N more seconds..." }
