from django.db import models
from django.conf import settings
from vehicles.models import Vehicle


class Customer(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='customer_profiles'
    )
    name = models.CharField(max_length=150)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20)
    address = models.TextField(blank=True)
    identity_type = models.CharField(max_length=50, blank=True, default='Driving Licence')
    identity_number = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.phone})"


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING = 'Pending', 'Pending'
        CONFIRMED = 'Confirmed', 'Confirmed'
        COMPLETED = 'Completed', 'Completed'
        CANCELLED = 'Cancelled', 'Cancelled'

    booking_id = models.CharField(max_length=30, unique=True, help_text="e.g. BK-1001 or TAMS-1001")
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='bookings')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='bookings')
    pickup_location = models.CharField(max_length=255)
    destination_location = models.CharField(max_length=255)
    pickup_date = models.DateField()
    return_date = models.DateField()
    passengers = models.PositiveIntegerField(default=1)
    notes = models.TextField(blank=True)
    base_fare = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.booking_id} - {self.customer.name} ({self.vehicle.make_model})"

    def save(self, *args, **kwargs):
        if not self.booking_id:
            last = Booking.objects.order_by('-id').first()
            next_num = 1001 if not last else last.id + 1001
            self.booking_id = f"BK-{next_num}"
        super().save(*args, **kwargs)
