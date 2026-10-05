"""
URL configuration for TAMS project.
"""
from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView
from django.conf import settings
from django.conf.urls.static import static

# Frontend template mappings
frontend_patterns = [
    path('', TemplateView.as_view(template_name='index.html'), name='root'),
    path('index.html', TemplateView.as_view(template_name='index.html'), name='page-login'),
    path('register.html', TemplateView.as_view(template_name='register.html'), name='page-register'),

    # Admin pages
    path('admin-dashboard.html', TemplateView.as_view(template_name='admin-dashboard.html'), name='page-admin-dashboard'),
    path('fleet-management.html', TemplateView.as_view(template_name='fleet-management.html'), name='page-fleet'),
    path('driver-management.html', TemplateView.as_view(template_name='driver-management.html'), name='page-driver-mgmt'),
    path('manage-bookings.html', TemplateView.as_view(template_name='manage-bookings.html'), name='page-manage-bookings'),
    path('duty-slip-management.html', TemplateView.as_view(template_name='duty-slip-management.html'), name='page-duty-slip-mgmt'),
    path('duty-slips.html', TemplateView.as_view(template_name='duty-slip-management.html'), name='page-duty-slips-alias'),
    path('maintenance.html', TemplateView.as_view(template_name='maintenance.html'), name='page-maintenance'),
    path('billing.html', TemplateView.as_view(template_name='billing.html'), name='page-billing'),
    path('reports.html', TemplateView.as_view(template_name='reports.html'), name='page-reports'),

    # Customer pages
    path('customer-dashboard.html', TemplateView.as_view(template_name='customer-dashboard.html'), name='page-customer-dashboard'),
    path('search-vehicles.html', TemplateView.as_view(template_name='search-vehicles.html'), name='page-search-vehicles'),
    path('book-vehicle.html', TemplateView.as_view(template_name='book-vehicle.html'), name='page-book-vehicle'),
    path('my-bookings.html', TemplateView.as_view(template_name='my-bookings.html'), name='page-my-bookings'),
    path('customer-invoices.html', TemplateView.as_view(template_name='customer-invoices.html'), name='page-customer-invoices'),
    path('customer-profile.html', TemplateView.as_view(template_name='customer-profile.html'), name='page-customer-profile'),

    # Driver pages
    path('driver-dashboard.html', TemplateView.as_view(template_name='driver-dashboard.html'), name='page-driver-dashboard'),
    path('driver-trips.html', TemplateView.as_view(template_name='driver-trips.html'), name='page-driver-trips'),
    path('driver-duty-slips.html', TemplateView.as_view(template_name='driver-duty-slips.html'), name='page-driver-duty-slips'),
    path('driver-earnings.html', TemplateView.as_view(template_name='driver-earnings.html'), name='page-driver-earnings'),
    path('driver-profile.html', TemplateView.as_view(template_name='driver-profile.html'), name='page-driver-profile'),
]

urlpatterns = [
    # Django Admin
    path('admin/', admin.site.urls),

    # REST APIs v1
    path('api/v1/auth/', include('accounts.urls')),
    path('api/v1/', include('vehicles.urls')),
    path('api/v1/', include('drivers.urls')),
    path('api/v1/', include('bookings.urls')),
    path('api/v1/', include('duty_slips.urls')),
    path('api/v1/', include('billing.urls')),
    path('api/v1/', include('payments.urls')),
    path('api/v1/', include('maintenance.urls')),
    path('api/v1/', include('reports.urls')),

    # Frontend pages
    *frontend_patterns,
]

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATICFILES_DIRS[0])
