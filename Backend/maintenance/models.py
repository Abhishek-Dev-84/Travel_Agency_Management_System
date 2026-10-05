from django.db import models
from vehicles.models import Vehicle


class WorkOrder(models.Model):
    class Priority(models.TextChoices):
        NORMAL = 'Normal', 'Normal'
        HIGH = 'High', 'High'
        URGENT = 'Urgent', 'Urgent'

    class Status(models.TextChoices):
        SCHEDULED = 'Scheduled', 'Scheduled'
        IN_SERVICE = 'In Service', 'In Service'
        COMPLETED = 'Completed', 'Completed'
        CANCELLED = 'Cancelled', 'Cancelled'

    work_order_id = models.CharField(max_length=30, unique=True, help_text="e.g. WO-2026-001")
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='work_orders')
    service_type = models.CharField(max_length=100)
    issue_description = models.TextField()
    priority = models.CharField(max_length=20, choices=Priority.choices, default=Priority.NORMAL)
    garage_name = models.CharField(max_length=150, blank=True)
    estimated_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    actual_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    scheduled_date = models.DateField()
    completion_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SCHEDULED)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-scheduled_date', '-created_at']

    def __str__(self):
        return f"{self.work_order_id} - {self.vehicle.make_model} ({self.status})"

    def save(self, *args, **kwargs):
        if not self.work_order_id:
            last = WorkOrder.objects.order_by('-id').first()
            next_num = 1 if not last else last.id + 1
            self.work_order_id = f"WO-2026-{str(next_num).zfill(3)}"

        super().save(*args, **kwargs)

        # Sync vehicle status based on work order status (Rule 12)
        if self.status == self.Status.IN_SERVICE:
            if self.vehicle.status != Vehicle.Status.MAINTENANCE:
                self.vehicle.status = Vehicle.Status.MAINTENANCE
                self.vehicle.save(update_fields=['status'])
        elif self.status == self.Status.COMPLETED:
            if self.vehicle.status == Vehicle.Status.MAINTENANCE:
                self.vehicle.status = Vehicle.Status.AVAILABLE
                self.vehicle.save(update_fields=['status'])
