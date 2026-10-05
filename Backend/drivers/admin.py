from django.contrib import admin
from .models import Driver


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ('driver_id', 'name', 'phone', 'license_number', 'license_expiry', 'status', 'rating')
    list_filter = ('status', 'blood_group')
    search_fields = ('name', 'driver_id', 'phone', 'license_number')
