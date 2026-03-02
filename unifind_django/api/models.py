"""
api/models.py

Database models for UniFind. These classes map directly to the
tables defined in schema.sql — the same ones the PHP side uses.

IMPORTANT: The Meta class on each model has `managed = False`.
This tells Django "don't try to CREATE or ALTER this table,
it already exists." If you're starting with a fresh database
(e.g. new XAMPP install), set managed = True temporarily, run
`python manage.py migrate`, then set it back to False.
Or just run schema.sql directly in phpMyAdmin like a normal person.

The schema we're matching:
  users(id, full_name, email, password_hash, is_verified, created_at)
  email_verification_tokens(id, user_id, token_hash, expires_at, used_at, created_at)
  listings(id, user_id, name, description, price, category, image_path, is_approved, created_at)
"""

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager


# ============================================================
# USER MANAGER — the factory that builds User objects.
# Django requires this if you use a custom User model.
# It's like a foreman for the User assembly line.
# ============================================================

class UserManager(BaseUserManager):

    def create_user(self, email, password=None, **extra_fields):
        """
        Standard user creation. Used when registering through the API.
        We normalize the email (lowercases the domain part) to prevent
        someone registering as RYISHA@MONTCLAIR.EDU and sneaking in.
        """
        if not email:
            # No email? Get out of here.
            raise ValueError('An email address is required, genius.')

        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra_fields)

        if password:
            # We store the salted hash ourselves in the view.
            # set_unusable_password() tells Django "this user has no
            # Django-managed password." We manage the password field directly.
            # If you call set_password() here it'll overwrite our hash with
            # Django's own PBKDF2 hash and everything breaks. Don't do that.
            user.password_hash = password  # 'password' here is already our hash
        else:
            user.set_unusable_password()

        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """
        Creates a superuser for the Django /admin/ panel.
        The createsuperuser command calls this.
        Note: superuser password is handled by Django normally here,
        since superusers are created via command line, not the API.
        """
        from .utils import hash_password
        extra_fields.setdefault('is_verified', True)
        extra_fields.setdefault('is_admin', True)

        user = self.model(email=self.normalize_email(email).lower(), **extra_fields)
        if password:
            user.password_hash = hash_password(password)
        user.save(using=self._db)
        return user


# ============================================================
# USER MODEL — the main character
# ============================================================

class User(AbstractBaseUser):
    """
    Custom user model that matches the `users` table in schema.sql.

    We extend AbstractBaseUser instead of AbstractUser because
    AbstractUser has a bunch of fields (username, first_name, last_name,
    groups, permissions) that we don't want and would need to override
    anyway. AbstractBaseUser gives us just the authentication machinery
    with none of the opinions. Clean slate. Beautiful.
    """

    password = None  # we use password_hash instead, get outta here
    
    full_name = models.CharField(max_length=120)

    # Mirrors schema.sql: id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    # Django adds this automatically. Don't define it yourself.

    # Mirrors schema.sql: full_name VARCHAR(120) NOT NULL
    full_name = models.CharField(max_length=120)

    # Mirrors schema.sql: email VARCHAR(190) NOT NULL UNIQUE
    email = models.EmailField(max_length=190, unique=True)

    # Mirrors schema.sql: password_hash VARCHAR(255) NOT NULL
    # We store our salted SHA-256 hash in here directly.
    # Format: "salt$hash" — see utils.py for the gory details.
    # Django's AbstractBaseUser has a `password` field by default but
    # we're bypassing it because the PHP side already has a specific
    # hash format and we need to match it. More on this in views.py.
    password_hash = models.CharField(max_length=255, db_column='password_hash')

    # Mirrors schema.sql: is_verified TINYINT(1) NOT NULL DEFAULT 0
    is_verified = models.BooleanField(default=False)

    # Not in the original schema but Django needs this for /admin/ to work.
    # We'll add it as a virtual field — it won't create a new column
    # because managed = False. It just lives in Python memory.
    is_admin = models.BooleanField(default=False, db_column='is_admin')

    # Mirrors schema.sql: created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    created_at = models.DateTimeField(auto_now_add=True)

    # This is the field Django uses as the "username" for authentication.
    # We're using email because usernames are for people who have MySpace.
    USERNAME_FIELD = 'email'

    # Fields required when using createsuperuser command, besides USERNAME_FIELD.
    REQUIRED_FIELDS = ['full_name']

    # Attach our custom manager.
    objects = UserManager()

    # AbstractBaseUser requires these properties for Django's permission system.
    # is_staff controls access to /admin/. We just tie it to is_admin.

    @property
    def is_staff(self):
        return self.is_admin

    @property
    def is_active(self):
        # A user is "active" in Django's eyes if they're verified.
        # Banned/deactivated users would have is_verified = False (or we'd add
        # a separate is_banned column in a future milestone).
        return self.is_verified

    def has_perm(self, perm, obj=None):
        # Admins can do anything. Regular users can do nothing special.
        return self.is_admin

    def has_module_perms(self, app_label):
        return self.is_admin

    def __str__(self):
        return f'{self.full_name} <{self.email}>'

    class Meta:
        db_table = 'users'  # Match the exact table name from schema.sql
        managed = False     # Don't let Django touch the table structure.
                            # The table already exists. Leave it alone.


# ============================================================
# EMAIL VERIFICATION TOKEN MODEL
# ============================================================

class EmailVerificationToken(models.Model):
    """
    Matches the `email_verification_tokens` table in schema.sql.

    How verification works:
    1. User registers → we generate a random 64-char hex string (the raw token)
    2. We SHA-256 hash the raw token and store THAT in this table
    3. We email the RAW token to the user as a link
    4. User clicks link → we SHA-256 hash the token from the URL and compare
       it to what's in the database
    5. If they match AND it's not expired AND it hasn't been used → verified!

    Why store the hash instead of the raw token?
    Because if someone somehow reads your database (SQL injection, 
    compromised cPanel, your roommate snooping around), they can't just
    copy a verification token and verify someone else's account.
    The raw token only ever exists in the email and in memory. Briefly.
    """

    # Mirrors schema.sql: user_id INT UNSIGNED NOT NULL (FK → users.id)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='verification_tokens'
    )

    # Mirrors schema.sql: token_hash CHAR(64) NOT NULL
    # SHA-256 produces a 64-character hex string. That's not a coincidence.
    token_hash = models.CharField(max_length=64)

    # Mirrors schema.sql: expires_at DATETIME NOT NULL
    expires_at = models.DateTimeField()

    # Mirrors schema.sql: used_at DATETIME NULL
    # NULL = not yet used. Non-null = already clicked, link is dead.
    used_at = models.DateTimeField(null=True, blank=True)

    # Mirrors schema.sql: created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        status = 'used' if self.used_at else ('expired' if self.is_expired() else 'valid')
        return f'Token for {self.user.email} [{status}]'

    def is_expired(self):
        from django.utils import timezone
        return timezone.now() > self.expires_at

    class Meta:
        db_table = 'email_verification_tokens'
        managed = False  # Already exists in the database. Hands off, Django.


# ============================================================
# LISTING MODEL
# ============================================================

class Listing(models.Model):
    """
    Matches the `listings` table in schema.sql.
    Used for Milestone 2 onward. Defined here now so the model
    exists and doesn't cause import errors later.
    """

    # Mirrors schema.sql: user_id INT UNSIGNED NOT NULL (FK → users.id)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='listings'
    )

    # Mirrors schema.sql: name VARCHAR(150) NOT NULL
    name = models.CharField(max_length=150)

    # Mirrors schema.sql: description TEXT NOT NULL
    description = models.TextField()

    # Mirrors schema.sql: price DECIMAL(10,2) NOT NULL
    price = models.DecimalField(max_digits=10, decimal_places=2)

    # Mirrors schema.sql: category VARCHAR(80) NOT NULL
    category = models.CharField(max_length=80)

    # Mirrors schema.sql: image_path VARCHAR(255) NOT NULL
    image_path = models.CharField(max_length=255)

    # Mirrors schema.sql: is_approved TINYINT(1) NOT NULL DEFAULT 1
    is_approved = models.BooleanField(default=True)

    # Mirrors schema.sql: created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.name} — ${self.price} (by {self.user.email})'

    class Meta:
        db_table = 'listings'
        managed = False
        ordering = ['-created_at']  # Newest first, always.
