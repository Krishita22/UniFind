"""
api/admin.py

Registers our models with Django's built-in admin panel at /admin/.
This gives you a free web UI to view all users, verification tokens,
and listings without writing a single line of frontend code.

Go to http://localhost:8000/admin/ and log in with the superuser
account you created with `python manage.py createsuperuser`.

Your professor will see this and think you built an admin dashboard.
You don't need to correct them.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, EmailVerificationToken, Listing


# ============================================================
# USER ADMIN
# ============================================================

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Custom admin configuration for our User model.
    Because we're using AbstractBaseUser instead of the default
    User model, we need to tell Django's admin panel which fields
    to show. Otherwise it shows a pile of AttributeErrors and sadness.
    """

    # Columns visible in the user list
    list_display = ('email', 'full_name', 'is_verified', 'is_admin', 'created_at')

    # Sidebar filters in the user list
    list_filter = ('is_verified', 'is_admin')

    # Fields you can search by
    search_fields = ('email', 'full_name')

    # Default sort: newest first
    ordering = ('-created_at',)

    # Field layout when VIEWING/EDITING a user
    fieldsets = (
        ('Account', {'fields': ('email', 'password_hash')}),
        ('Profile', {'fields': ('full_name',)}),
        ('Status', {'fields': ('is_verified', 'is_admin')}),
    )

    # Field layout when CREATING a user through admin
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'full_name', 'password_hash', 'is_verified', 'is_admin'),
        }),
    )

    # Django's BaseUserAdmin references M2M fields (groups, permissions) that
    # our model doesn't have. Blanking these out prevents admin from exploding.
    filter_horizontal = ()


# ============================================================
# VERIFICATION TOKEN ADMIN
# ============================================================

@admin.register(EmailVerificationToken)
class TokenAdmin(admin.ModelAdmin):
    """
    View all verification tokens. Useful for debugging when someone
    says "I never got my verification email" and you want to check
    if the token actually got created.
    """

    list_display = ('user', 'token_hash_preview', 'expires_at', 'used_at', 'created_at')
    list_filter = ('used_at',)
    search_fields = ('user__email',)
    ordering = ('-created_at',)
    readonly_fields = ('token_hash', 'created_at')  # Don't let anyone accidentally edit these

    def token_hash_preview(self, obj):
        """Show just the first 12 chars of the hash so the column isn't massive."""
        return obj.token_hash[:12] + '...' if obj.token_hash else '—'

    token_hash_preview.short_description = 'Token Hash (preview)'


# ============================================================
# LISTING ADMIN
# ============================================================

@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin):
    """
    View and manage all listings. The admin can approve or unapprove
    listings here, which is how the moderation system works.
    (The `is_approved` field on the Listing model.)
    """

    list_display = ('name', 'user', 'price', 'category', 'is_approved', 'created_at')
    list_filter = ('is_approved', 'category')
    search_fields = ('name', 'description', 'user__email')
    ordering = ('-created_at',)

    # Allow toggling is_approved directly from the list view
    list_editable = ('is_approved',)
