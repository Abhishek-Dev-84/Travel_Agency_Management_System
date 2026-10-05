from django.contrib import admin
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('payment_id', 'invoice', 'amount', 'payment_method', 'payment_status', 'transaction_ref', 'is_demo', 'created_at')
    list_filter = ('payment_status', 'payment_method', 'is_demo')
    search_fields = ('payment_id', 'transaction_ref', 'invoice__invoice_id')
