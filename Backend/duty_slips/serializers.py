from rest_framework import serializers
from .models import DutySlip
from bookings.models import Booking
from drivers.models import Driver
from vehicles.models import Vehicle


class DutySlipSerializer(serializers.ModelSerializer):
    booking_id = serializers.PrimaryKeyRelatedField(
        queryset=Booking.objects.all(),
        source='booking',
        write_only=True,
        required=True
    )
    driver_id = serializers.PrimaryKeyRelatedField(
        queryset=Driver.objects.all(),
        source='driver',
        write_only=True,
        required=True
    )
    vehicle_id = serializers.PrimaryKeyRelatedField(
        queryset=Vehicle.objects.all(),
        source='vehicle',
        write_only=True,
        required=False
    )

    booking_code = serializers.CharField(source='booking.booking_id', read_only=True)
    driver_name = serializers.CharField(source='driver.name', read_only=True)
    driver_phone = serializers.CharField(source='driver.phone', read_only=True)
    driver_code = serializers.CharField(source='driver.driver_id', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.make_model', read_only=True)
    vehicle_reg = serializers.CharField(source='vehicle.registration_number', read_only=True)

    class Meta:
        model = DutySlip
        fields = [
            'id', 'slip_id', 'booking_id', 'booking_code',
            'driver_id', 'driver_name', 'driver_phone', 'driver_code',
            'vehicle_id', 'vehicle_name', 'vehicle_reg',
            'date', 'time', 'pickup', 'destination',
            'customer_name', 'customer_phone',
            'start_odometer', 'end_odometer', 'fuel_level',
            'remarks', 'payout', 'status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'slip_id', 'created_at', 'updated_at']

    def validate(self, attrs):
        driver = attrs.get('driver')
        booking = attrs.get('booking')
        duty_date = attrs.get('date') or (booking.pickup_date if booking else None)

        if not duty_date and booking:
            attrs['date'] = booking.pickup_date
            duty_date = booking.pickup_date

        # Auto-fill vehicle from booking if not specified
        if not attrs.get('vehicle') and booking:
            attrs['vehicle'] = booking.vehicle

        # Auto-fill route and customer info if blank
        if booking:
            if not attrs.get('pickup'):
                attrs['pickup'] = booking.pickup_location
            if not attrs.get('destination'):
                attrs['destination'] = booking.destination_location
            if not attrs.get('customer_name'):
                attrs['customer_name'] = booking.customer.name
            if not attrs.get('customer_phone'):
                attrs['customer_phone'] = booking.customer.phone

        # Driver License validity check (Rule 12)
        if driver and duty_date:
            if driver.license_expiry < duty_date:
                raise serializers.ValidationError({
                    "driver": f"Driver '{driver.name}' cannot be assigned because their driving license expires on {driver.license_expiry} (before duty date {duty_date})."
                })

        # Driver Overlap check (Rule 12)
        if driver and duty_date:
            overlap = DutySlip.objects.filter(
                driver=driver,
                date=duty_date,
                status__in=[DutySlip.Status.UPCOMING, DutySlip.Status.IN_PROGRESS]
            )
            if self.instance:
                overlap = overlap.exclude(pk=self.instance.pk)
            if overlap.exists():
                conflict = overlap.first()
                raise serializers.ValidationError({
                    "driver": f"Driver '{driver.name}' already has an overlapping trip assigned on {duty_date} ({conflict.slip_id}). Please assign a different driver."
                })

        return attrs
