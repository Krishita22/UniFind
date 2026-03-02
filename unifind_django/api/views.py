"""
api/views.py

The API endpoints. This is where requests come in, get validated,
do database things, and send back a response.

Each function decorated with @api_view is one endpoint.
Flutter calls these. They return JSON. That's the whole deal.

Endpoint summary:
  POST /api/register/        ← creates a new unverified user, sends email
  GET  /api/verify-email/    ← user clicks link from email, gets verified
  POST /api/login/           ← returns auth token on success
  POST /api/logout/          ← invalidates the auth token
  GET  /api/me/              ← returns current user's info (requires token)
  POST /api/resend-verify/   ← resends verification email if user is impatient
"""

import logging
from datetime import timedelta

from django.utils import timezone

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token

from .models import User, EmailVerificationToken
from .utils import hash_password, verify_password, generate_raw_token, hash_token, is_valid_montclair_email
from .gmail_service import send_verification_email

logger = logging.getLogger(__name__)

# How long a verification token stays valid. 24 hours. If you haven't
# checked your email in 24 hours that's a personal problem.
VERIFICATION_TOKEN_TTL_HOURS = 24

# Rate limiting: how long a user has to wait before requesting another
# verification email. 2 minutes. Prevents people from spamming the
# Gmail API quota and getting us rate-limited. Not that this is likely.
RESEND_COOLDOWN_SECONDS = 120


# ============================================================
# REGISTER
# POST /api/register/
# Request body: { "email": "...", "password": "...", "full_name": "..." }
# ============================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """
    Creates a new UniFind account.

    The happy path:
      1. Validate inputs (all fields present, valid email format)
      2. Check it's a montclair.edu email or GTFO
      3. Check nobody's already registered with that email
      4. Hash the password with a random salt
      5. Create the user (is_verified = False)
      6. Generate a verification token, store its hash, send raw token via email
      7. Return 201 and tell the user to check their email

    The sad paths are many and varied. We return specific error messages
    for each one so Flutter can display something useful to the user.
    """

    # Pull fields out of the request body.
    # .get() with a default prevents KeyError if Flutter sends incomplete data.
    email = request.data.get('email', '').lower().strip()
    password = request.data.get('password', '')
    full_name = request.data.get('full_name', '').strip()

    # ---- Input validation ----
    # Check all three fields exist and aren't just whitespace.
    # We check them all at once so we can return a specific message.
    if not email:
        return Response(
            {'error': 'Email is required.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if not full_name:
        return Response(
            {'error': 'Full name is required.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if not password:
        return Response(
            {'error': 'Password is required.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Password must be at least 8 characters and contain letters and numbers.
    # Matching the validation from the PHP register.php.
    if len(password) < 8:
        return Response(
            {'error': 'Password must be at least 8 characters.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    has_letter = any(c.isalpha() for c in password)
    has_number = any(c.isdigit() for c in password)
    if not (has_letter and has_number):
        return Response(
            {'error': 'Password must contain at least one letter and one number.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- The bouncer check ----
    # Is this actually a montclair.edu email? Because if not, bye.
    if not is_valid_montclair_email(email):
        return Response(
            {'error': 'Only @montclair.edu email addresses are allowed. '
                      'UniFind is for MSU students and staff only.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Duplicate check ----
    # Already have an account? Go log in instead of registering again.
    if User.objects.filter(email=email).exists():
        return Response(
            {'error': 'An account with this email already exists.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Password hashing ----
    # Turn the plaintext password into a "salt$hash" string.
    # The plaintext password ceases to exist after this line.
    # It will never be stored. It will never be logged. It will never be seen again.
    # Moment of silence for the plaintext password.
    hashed_password = hash_password(password)

    # ---- Create the user ----
    # is_verified starts as False. They need to click the email link first.
    # They can't log in until is_verified is True.
    try:
        user = User.objects.create(
            email=email,
            full_name=full_name,
            password_hash=hashed_password,
            is_verified=False,
            is_admin=False,
        )
    except Exception as e:
        logger.error(f"Failed to create user {email}: {e}")
        return Response(
            {'error': 'Account creation failed. Please try again.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    # ---- Generate and store verification token ----
    # Raw token → goes in the email URL (never stored)
    # Token hash → goes in the database
    raw_token = generate_raw_token()
    token_hash = hash_token(raw_token)
    expiry = timezone.now() + timedelta(hours=VERIFICATION_TOKEN_TTL_HOURS)

    try:
        EmailVerificationToken.objects.create(
            user=user,
            token_hash=token_hash,
            expires_at=expiry,
        )
    except Exception as e:
        # Token creation failed. Delete the user so they can try again.
        # An unverified user with no token is a zombie account.
        logger.error(f"Failed to create verification token for {email}: {e}")
        user.delete()
        return Response(
            {'error': 'Account creation failed (token error). Please try again.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    # ---- Send the verification email ----
    email_sent = send_verification_email(email, full_name, raw_token)

    if not email_sent:
        # Email failed. We still created the account and token, so the user
        # can use the resend endpoint. Tell them what happened.
        logger.warning(f"Verification email failed for {email} — account created, token saved")
        return Response(
            {
                'message': 'Account created, but the verification email failed to send. '
                           'Use the resend option to try again.',
                'email_sent': False,
            },
            status=status.HTTP_201_CREATED  # Still 201 — the account WAS created
        )

    # ---- Success ----
    return Response(
        {
            'message': f'Account created! Check your Montclair email ({email}) '
                       f'to verify your account before logging in.',
            'email_sent': True,
        },
        status=status.HTTP_201_CREATED
    )


# ============================================================
# VERIFY EMAIL
# GET /api/verify-email/?token=<raw_token>&email=<email>
# This endpoint is hit when the user clicks the link in their email.
# It returns a plain text/JSON response. Flutter can handle it or
# the user can just see it in their browser — both work.
# ============================================================

@api_view(['GET'])
@permission_classes([AllowAny])
def verify_email(request):
    """
    Marks a user as verified when they click the link from their email.

    The verification flow:
      1. Extract token and email from query parameters
      2. Find the user by email
      3. If already verified, tell them and move on
      4. SHA-256 hash the provided token
      5. Look for an unused, unexpired token record with that hash
      6. If found: mark user as verified, mark token as used
      7. If not found: tell user the link is expired or invalid
    """

    raw_token = request.query_params.get('token', '').strip()
    email = request.query_params.get('email', '').lower().strip()

    # ---- Basic parameter validation ----
    if not raw_token or not email:
        return Response(
            {'error': 'Invalid verification link. Missing token or email.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Find the user ----
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # Don't reveal whether the email is registered. Just say invalid.
        return Response(
            {'error': 'Invalid verification link.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Already verified? ----
    # This can happen if they click the link twice, or if the PHP side
    # already verified them. No harm done. Just tell them.
    if user.is_verified:
        return Response(
            {'message': 'Your email is already verified. You can log in.'},
            status=status.HTTP_200_OK
        )

    # ---- Hash the provided token and find it in the database ----
    provided_hash = hash_token(raw_token)
    now = timezone.now()

    # Get all unused, unexpired tokens for this user.
    # There should usually be exactly one, but we handle multiples gracefully.
    valid_token = EmailVerificationToken.objects.filter(
        user=user,
        used_at__isnull=True,       # Not yet used
        expires_at__gt=now,         # Not expired
    ).first()

    if valid_token is None:
        # Token doesn't exist, is expired, or was already used.
        return Response(
            {
                'error': 'This verification link has expired or already been used. '
                         'Please request a new one.',
                'can_resend': True,
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    # Compare the hash of the provided token against what we stored.
    # Use a constant-time comparison. We're being thorough.
    import secrets as sec
    if not sec.compare_digest(valid_token.token_hash, provided_hash):
        # The token exists but the hash doesn't match. That's suspicious.
        return Response(
            {'error': 'Invalid verification link.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- We have a winner. Mark everything as done. ----
    # Update the user: verified = True
    User.objects.filter(pk=user.pk).update(is_verified=True)

    # Mark the token as used so it can't be replayed
    EmailVerificationToken.objects.filter(pk=valid_token.pk).update(
        used_at=now
    )

    return Response(
        {'message': 'Email verified successfully! You can now log in to UniFind.'},
        status=status.HTTP_200_OK
    )


# ============================================================
# LOGIN
# POST /api/login/
# Request body: { "email": "...", "password": "..." }
# Response: { "token": "...", "user": { "email": ..., "full_name": ..., ... } }
# ============================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """
    Authenticates a user and returns an auth token.

    The token is what Flutter stores (in SharedPreferences or wherever)
    and sends with every subsequent request in the Authorization header:
      Authorization: Token <token_value_here>

    DRF's TokenAuthentication middleware reads that header, looks up the
    token in the authtoken_token table, and attaches the user to the request
    as request.user. That's how protected endpoints know who's calling.

    Security note: We always return the same generic error message for both
    "wrong email" and "wrong password." This prevents user enumeration —
    an attacker shouldn't be able to use your login endpoint as an oracle
    to discover which emails are registered.
    """

    email = request.data.get('email', '').lower().strip()
    password = request.data.get('password', '')

    # ---- Input validation ----
    if not email or not password:
        return Response(
            {'error': 'Email and password are required.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Find the user ----
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # User doesn't exist. Return the same message as wrong password.
        # Don't tell them "that email isn't registered." That's user enumeration.
        # We don't do that here.
        return Response(
            {'error': 'Invalid email or password.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # ---- Check password ----
    if not verify_password(password, user.password_hash):
        # Wrong password. Same message as user not found. See above.
        return Response(
            {'error': 'Invalid email or password.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # ---- Check verification status ----
    if not user.is_verified:
        # Correct credentials, but they haven't clicked the email link yet.
        # We DO tell them this specifically, because knowing the email+password
        # is correct means they already have an account — no enumeration risk.
        return Response(
            {
                'error': 'Please verify your email before logging in. '
                         'Check your inbox for the verification link.',
                'can_resend': True,
                'email': email,
            },
            status=status.HTTP_403_FORBIDDEN
        )

    # ---- Issue auth token ----
    # get_or_create means: if they already have a token from a previous session,
    # reuse it. If not, make a new one. Either way, they get a token.
    # One user = one token. If they log in on two devices they share the token.
    # This is fine for a demo. A real app would use per-device tokens.
    token, _ = Token.objects.get_or_create(user=user)

    # ---- Success ----
    return Response(
        {
            'token': token.key,
            'user': {
                'email': user.email,
                'full_name': user.full_name,
                'is_admin': user.is_admin,
                'is_verified': user.is_verified,
            }
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# LOGOUT
# POST /api/logout/
# Requires: Authorization: Token <token>
# ============================================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    Invalidates the user's auth token.

    After this, their token is deleted from the database. Any subsequent
    request with that token will get a 401. Flutter should delete the
    stored token from local storage on receiving a 200 here.

    This is a POST even though it's logically a "delete" operation,
    because the token is passed in the Authorization header (not the URL),
    and DELETE requests don't conventionally have request bodies.
    """

    try:
        # Delete their token. It's gone. If they want to use the app again
        # they'll need to log in and get a new one.
        request.user.auth_token.delete()
    except Exception:
        # Token was already gone somehow. That's... fine. We wanted it gone.
        pass

    return Response(
        {'message': 'Logged out successfully.'},
        status=status.HTTP_200_OK
    )


# ============================================================
# GET CURRENT USER
# GET /api/me/
# Requires: Authorization: Token <token>
# ============================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """
    Returns the currently authenticated user's profile information.

    Flutter can call this on app startup to verify the stored token
    is still valid and get up-to-date user info.
    If the token is expired/deleted, DRF returns 401 automatically
    before this function even runs.
    """

    user = request.user
    return Response({
        'email': user.email,
        'full_name': user.full_name,
        'is_admin': user.is_admin,
        'is_verified': user.is_verified,
        'member_since': user.created_at.isoformat() if user.created_at else None,
    })


# ============================================================
# RESEND VERIFICATION EMAIL
# POST /api/resend-verify/
# Request body: { "email": "..." }
# ============================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def resend_verification(request):
    """
    Resends the verification email to a user who hasn't verified yet.
    For when they lost the email, it went to spam, or they just didn't
    get around to it within 24 hours because they were busy. We've all
    been there.

    Rate limited to once every 2 minutes per user. Because we're not
    made of Gmail API quota.
    """

    email = request.data.get('email', '').lower().strip()

    if not email:
        return Response(
            {'error': 'Email is required.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # ---- Find user ----
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # Don't reveal whether the email is registered. Same vague message.
        return Response(
            {'message': 'If that email is registered and unverified, '
                        'a new verification email has been sent.'},
            status=status.HTTP_200_OK
        )

    # Already verified? Nothing to resend.
    if user.is_verified:
        return Response(
            {'message': 'This account is already verified. Please log in.'},
            status=status.HTTP_200_OK
        )

    # ---- Rate limit check ----
    # When was the most recent token created for this user?
    latest_token = EmailVerificationToken.objects.filter(
        user=user
    ).order_by('-created_at').first()

    if latest_token:
        seconds_since_last = (timezone.now() - latest_token.created_at).total_seconds()
        if seconds_since_last < RESEND_COOLDOWN_SECONDS:
            wait_time = int(RESEND_COOLDOWN_SECONDS - seconds_since_last)
            return Response(
                {'error': f'Please wait {wait_time} more seconds before requesting another email.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )

    # ---- Generate and send a new token ----
    raw_token = generate_raw_token()
    token_hash = hash_token(raw_token)
    expiry = timezone.now() + timedelta(hours=VERIFICATION_TOKEN_TTL_HOURS)

    EmailVerificationToken.objects.create(
        user=user,
        token_hash=token_hash,
        expires_at=expiry,
    )

    email_sent = send_verification_email(email, user.full_name, raw_token)

    if not email_sent:
        return Response(
            {'error': 'Failed to send email. Please try again in a few minutes.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    return Response(
        {'message': f'Verification email sent to {email}. Check your inbox.'},
        status=status.HTTP_200_OK
    )
