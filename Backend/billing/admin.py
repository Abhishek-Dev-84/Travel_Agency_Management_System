from django.contrib import admin
from .models import Invoice


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_id', 'customer', 'grand_total', 'payment_status', 'payment_method', 'issue_date', 'due_date')
    list_filter = ('payment_status', 'payment_method', 'issue_date')
    search_fields = ('invoice_id', 'customer__name', 'booking__booking_id')
