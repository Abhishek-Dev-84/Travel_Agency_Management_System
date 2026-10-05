from rest_framework import serializers
from .models import Driver


class DriverSerializer(serializers.ModelSerializer):
    is_license_valid = serializers.ReadOnlyField()
    license_status = serializers.ReadOnlyField()

    class Meta:
        model = Driver
        fields = [
            'id', 'driver_id', 'user', 'name', 'phone', 'email',
            'license_number', 'license_expiry', 'experience_years',
            'blood_group', 'address', 'status', 'rating',
            'is_license_valid', 'license_status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'driver_id', 'created_at', 'updated_at', 'is_license_valid', 'license_status']

    def validate_phone(self, value):
        val = value.strip()
        qs = Driver.objects.filter(phone=val)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("A driver with this phone number already exists.")
        return val

    def validate_license_number(self, value):
        val = value.strip().upper()
        qs = Driver.objects.filter(license_number__iexact=val)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("This license number is already registered.")
        return val
