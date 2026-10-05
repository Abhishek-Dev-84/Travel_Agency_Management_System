from django.contrib import admin
from .models import DutySlip


@admin.register(DutySlip)
class DutySlipAdmin(admin.ModelAdmin):
    list_display = ('slip_id', 'booking', 'driver', 'vehicle', 'date', 'status', 'payout')
    list_filter = ('status', 'date')
    search_fields = ('slip_id', 'booking__booking_id', 'driver__name', 'customer_name')
