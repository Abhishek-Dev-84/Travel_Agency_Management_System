from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Administrator'
        STAFF = 'STAFF', 'Staff'
        DRIVER = 'DRIVER', 'Driver'
        CUSTOMER = 'CUSTOMER', 'Customer'

    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.CUSTOMER,
        help_text='Designates the role and access level of the user.'
    )
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    blood_group = models.CharField(max_length=10, blank=True)
    identity_type = models.CharField(max_length=50, blank=True, default='Driving Licence')
    identity_number = models.CharField(max_length=50, blank=True)

    # Use email as unique identifier if provided
    email = models.EmailField(unique=True)

    def save(self, *args, **kwargs):
        # Automatically align is_staff / is_superuser for ADMIN role
        if self.role == self.Role.ADMIN:
            self.is_staff = True
        elif self.role == self.Role.STAFF:
            self.is_staff = True
        super().save(*args, **kwargs)

    @property
    def full_name(self):
        name = f"{self.first_name} {self.last_name}".strip()
        return name if name else self.username

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
