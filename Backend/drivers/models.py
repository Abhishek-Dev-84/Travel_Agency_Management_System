from django.db import models
from django.conf import settings
from django.utils import timezone
from datetime import timedelta


class Driver(models.Model):
    class Status(models.TextChoices):
        AVAILABLE = 'Available', 'Available'
        ON_DUTY = 'On Duty', 'On Duty'
        ON_LEAVE = 'On Leave', 'On Leave'
        INACTIVE = 'Inactive', 'Inactive'

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='driver_account'
    )
    driver_id = models.CharField(max_length=20, unique=True, help_text="e.g. DRV001")
    name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20, unique=True)
    email = models.EmailField(blank=True)
    license_number = models.CharField(max_length=50, unique=True)
    license_expiry = models.DateField()
    experience_years = models.PositiveIntegerField(default=1)
    blood_group = models.CharField(max_length=10, blank=True)
    address = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.AVAILABLE)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=5.0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['driver_id']

    def __str__(self):
        return f"{self.name} ({self.driver_id})"

    @property
    def is_license_valid(self):
        return self.license_expiry >= timezone.now().date()

    @property
    def license_status(self):
        today = timezone.now().date()
        if self.license_expiry < today:
            return "Expired"
        if self.license_expiry <= today + timedelta(days=30):
            return "Expiring Soon"
        return "Valid"

    def save(self, *args, **kwargs):
        if not self.driver_id:
            last = Driver.objects.order_by('-id').first()
            next_num = 1 if not last else last.id + 1
            self.driver_id = f"DRV{str(next_num).zfill(3)}"
        super().save(*args, **kwargs)
