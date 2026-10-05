from django.contrib import admin
from .models import Vehicle


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('make_model', 'registration_number', 'vehicle_type', 'capacity', 'fuel_type', 'status', 'per_day_rate')
    list_filter = ('vehicle_type', 'status', 'fuel_type', 'transmission', 'ac')
    search_fields = ('make_model', 'registration_number')
