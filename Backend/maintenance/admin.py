from django.contrib import admin
from .models import WorkOrder


@admin.register(WorkOrder)
class WorkOrderAdmin(admin.ModelAdmin):
    list_display = ('work_order_id', 'vehicle', 'service_type', 'priority', 'status', 'scheduled_date', 'estimated_cost', 'actual_cost')
    list_filter = ('status', 'priority', 'scheduled_date')
    search_fields = ('work_order_id', 'vehicle__make_model', 'service_type', 'garage_name')
