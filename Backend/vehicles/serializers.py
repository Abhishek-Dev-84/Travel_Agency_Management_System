from rest_framework import serializers
from .models import Vehicle


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = [
            'id', 'make_model', 'registration_number', 'vehicle_type',
            'capacity', 'fuel_type', 'transmission', 'ac',
            'luggage_capacity', 'per_day_rate', 'status',
            'insurance_info', 'permit_info', 'description',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_registration_number(self, value):
        norm = value.strip().upper()
        qs = Vehicle.objects.filter(registration_number__iexact=norm)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("A vehicle with this registration number already exists.")
        return norm
