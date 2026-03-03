"""
unifind_django/urls.py

The master URL configuration. All roads lead here, then get
forwarded to the api app. Like a post office except it works.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # The admin panel. Your professor will be impressed.
    # Go to http://localhost:8000/admin/ after creating a superuser.
    path('admin/', admin.site.urls),

    # All actual API endpoints live under /api/
    # e.g. POST http://localhost:8000/api/register/
    #      POST http://localhost:8000/api/login/
    path('api/', include('api.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
# ^ the static() call lets Django serve uploaded media files during development.
# In production (which we are NOT doing) you'd let nginx handle that. But we
# are not in production. We are in a classroom. These are different places.
