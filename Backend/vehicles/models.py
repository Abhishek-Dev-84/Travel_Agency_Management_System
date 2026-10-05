from django.db import models


class Vehicle(models.Model):
    class VehicleType(models.TextChoices):
        SEDAN = 'Sedan', 'Sedan'
        SUV = 'SUV', 'SUV'
        HATCHBACK = 'Hatchback', 'Hatchback'
        VAN = 'Van', 'Van / Traveller'

    class FuelType(models.TextChoices):
        PETROL = 'Petrol', 'Petrol'
        DIESEL = 'Diesel', 'Diesel'
        CNG = 'CNG', 'CNG'
        ELECTRIC = 'Electric', 'Electric'

    class Transmission(models.TextChoices):
        MANUAL = 'Manual', 'Manual'
        AUTOMATIC = 'Automatic', 'Automatic'

    class Status(models.TextChoices):
        AVAILABLE = 'Available', 'Available'
        ON_TRIP = 'On Trip', 'On Trip'
        MAINTENANCE = 'Maintenance', 'Maintenance / In Service'
        UNAVAILABLE = 'Unavailable', 'Unavailable'

    make_model = models.CharField(max_length=120, help_text="e.g. Toyota Innova Crysta")
    registration_number = models.CharField(max_length=30, unique=True, help_text="e.g. OD 02 AB 1234")
    vehicle_type = models.CharField(max_length=20, choices=VehicleType.choices, default=VehicleType.SEDAN)
    capacity = models.PositiveIntegerField(default=4, help_text="Passenger seating capacity")
    fuel_type = models.CharField(max_length=20, choices=FuelType.choices, default=FuelType.PETROL)
    transmission = models.CharField(max_length=20, choices=Transmission.choices, default=Transmission.MANUAL)
    ac = models.BooleanField(default=True, verbose_name="Air Conditioned")
    luggage_capacity = models.CharField(max_length=50, blank=True, default="3 bags")
    per_day_rate = models.DecimalField(max_digits=10, decimal_places=2, default=2000.00)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.AVAILABLE)
    insurance_info = models.CharField(max_length=150, blank=True)
    permit_info = models.CharField(max_length=150, blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.make_model} ({self.registration_number})"
