from django.contrib import admin
from .models import Customer, Booking


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'email', 'identity_type', 'created_at')
    search_fields = ('name', 'phone', 'email')


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('booking_id', 'customer', 'vehicle', 'pickup_date', 'return_date', 'status', 'base_fare')
    list_filter = ('status', 'pickup_date')
    search_fields = ('booking_id', 'customer__name', 'vehicle__make_model')
