from django.db import models
from bookings.models import Booking
from drivers.models import Driver
from vehicles.models import Vehicle


class DutySlip(models.Model):
    class Status(models.TextChoices):
        UPCOMING = 'Upcoming', 'Upcoming'
        IN_PROGRESS = 'In Progress', 'In Progress'
        COMPLETED = 'Completed', 'Completed'
        CANCELLED = 'Cancelled', 'Cancelled'

    slip_id = models.CharField(max_length=30, unique=True, help_text="e.g. DS-2026-001")
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name='duty_slips')
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='duty_slips')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='duty_slips')
    date = models.DateField()
    time = models.CharField(max_length=20, default="08:00")
    pickup = models.CharField(max_length=255)
    destination = models.CharField(max_length=255)
    customer_name = models.CharField(max_length=150, blank=True)
    customer_phone = models.CharField(max_length=20, blank=True)
    start_odometer = models.PositiveIntegerField(null=True, blank=True)
    end_odometer = models.PositiveIntegerField(null=True, blank=True)
    fuel_level = models.CharField(max_length=50, blank=True, default="Full")
    remarks = models.TextField(blank=True)
    payout = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UPCOMING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.slip_id} - {self.driver.name} ({self.vehicle.make_model})"

    def save(self, *args, **kwargs):
        if not self.slip_id:
            last = DutySlip.objects.order_by('-id').first()
            next_num = 1 if not last else last.id + 1
            self.slip_id = f"DS-2026-{str(next_num).zfill(3)}"
        super().save(*args, **kwargs)
