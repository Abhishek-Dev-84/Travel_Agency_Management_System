from rest_framework import serializers
from .models import Invoice
from bookings.models import Booking
from datetime import timedelta
from django.utils import timezone


class InvoiceSerializer(serializers.ModelSerializer):
    booking_id = serializers.PrimaryKeyRelatedField(
        queryset=Booking.objects.all(),
        source='booking',
        write_only=True,
        required=True
    )
    booking_code = serializers.CharField(source='booking.booking_id', read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_email = serializers.CharField(source='customer.email', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.make_model', read_only=True)
    vehicle_reg = serializers.CharField(source='vehicle.registration_number', read_only=True)
    route = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Invoice
        fields = [
            'id', 'invoice_id', 'booking_id', 'booking_code',
            'customer_name', 'customer_email', 'customer_phone',
            'vehicle_name', 'vehicle_reg', 'route',
            'issue_date', 'due_date',
            'base_fare', 'discount', 'taxable_amount',
            'tax_rate', 'tax_amount', 'grand_total',
            'payment_status', 'payment_method', 'notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'invoice_id', 'taxable_amount', 'tax_rate',
            'tax_amount', 'grand_total', 'created_at', 'updated_at'
        ]

    def get_route(self, obj):
        if obj.booking:
            return f"{obj.booking.pickup_location} → {obj.booking.destination_location}"
        return "—"

    def validate(self, attrs):
        booking = attrs.get('booking')
        if booking:
            attrs['customer'] = booking.customer
            attrs['vehicle'] = booking.vehicle
            if not attrs.get('base_fare'):
                attrs['base_fare'] = booking.base_fare
            if not attrs.get('due_date'):
                attrs['due_date'] = timezone.now().date() + timedelta(days=7)
        return attrs
