from rest_framework import serializers
from django.utils import timezone
from .models import Customer, Booking
from vehicles.models import Vehicle


class CustomerSerializer(serializers.ModelSerializer):
    bookings_count = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = [
            'id', 'user', 'name', 'email', 'phone', 'address',
            'identity_type', 'identity_number', 'bookings_count', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'bookings_count']

    def get_bookings_count(self, obj):
        return obj.bookings.count()


class BookingSerializer(serializers.ModelSerializer):
    customer_id = serializers.PrimaryKeyRelatedField(
        queryset=Customer.objects.all(),
        source='customer',
        required=False,
        write_only=True
    )
    vehicle_id = serializers.PrimaryKeyRelatedField(
        queryset=Vehicle.objects.all(),
        source='vehicle',
        write_only=True
    )

    # Allow booking by vehicle name or make_model string (as frontend sends e.g. "Toyota Innova Crysta")
    vehicle_name = serializers.CharField(write_only=True, required=False, allow_blank=True)

    # Allow inline customer details when booking as guest/new customer
    customer_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    customer_phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    customer_email = serializers.EmailField(write_only=True, required=False, allow_blank=True)

    # Read-only enriched fields for frontend display
    customer = CustomerSerializer(read_only=True)
    vehicle_details = serializers.SerializerMethodField(read_only=True)
    duration_days = serializers.SerializerMethodField(read_only=True)
    duty_slip = serializers.SerializerMethodField(read_only=True)
    assigned_driver = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'booking_id', 'customer', 'customer_id',
            'customer_name', 'customer_phone', 'customer_email',
            'vehicle_id', 'vehicle_name', 'vehicle_details',
            'pickup_location', 'destination_location',
            'pickup_date', 'return_date', 'passengers',
            'notes', 'base_fare', 'status', 'duration_days',
            'duty_slip', 'assigned_driver',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'booking_id', 'created_at', 'updated_at', 'duration_days']

    def get_duty_slip(self, obj):
        ds = obj.duty_slips.first()
        if ds:
            return {
                'id': ds.id,
                'slip_id': ds.slip_id,
                'status': ds.status,
                'date': str(ds.date),
                'time': ds.time,
                'payout': str(ds.payout),
            }
        return None

    def get_assigned_driver(self, obj):
        ds = obj.duty_slips.first()
        if ds and ds.driver:
            return {
                'id': ds.driver.id,
                'driver_id': ds.driver.driver_id,
                'name': ds.driver.name,
                'phone': ds.driver.phone,
                'license_number': ds.driver.license_number,
                'license_expiry': str(ds.driver.license_expiry),
                'status': ds.driver.status,
            }
        return None

    def get_vehicle_details(self, obj):
        v = obj.vehicle
        return {
            'id': v.id,
            'make_model': v.make_model,
            'registration_number': v.registration_number,
            'vehicle_type': v.vehicle_type,
            'capacity': v.capacity,
            'fuel_type': v.fuel_type,
            'per_day_rate': str(v.per_day_rate)
        }

    def get_duration_days(self, obj):
        if obj.pickup_date and obj.return_date:
            days = (obj.return_date - obj.pickup_date).days + 1
            return max(1, days)
        return 1

    def validate(self, attrs):
        pickup_date = attrs.get('pickup_date')
        return_date = attrs.get('return_date')
        vehicle = attrs.get('vehicle')

        # If vehicle_name provided without vehicle_id, lookup vehicle
        vehicle_name = attrs.pop('vehicle_name', None)
        if not vehicle and vehicle_name:
            v_match = Vehicle.objects.filter(make_model__icontains=vehicle_name.strip()).first()
            if not v_match:
                raise serializers.ValidationError({"vehicle": f"Vehicle '{vehicle_name}' was not found in the fleet."})
            attrs['vehicle'] = v_match
            vehicle = v_match

        if not vehicle:
            raise serializers.ValidationError({"vehicle": "Please select a vehicle."})

        # Date validations
        if pickup_date and return_date:
            if return_date < pickup_date:
                raise serializers.ValidationError({"return_date": "Return date cannot be earlier than pickup date."})

        # Vehicle availability rule (Rule 12)
        if vehicle.status == Vehicle.Status.MAINTENANCE:
            raise serializers.ValidationError({"vehicle": f"Vehicle '{vehicle.make_model}' is currently in maintenance / under repair and cannot be booked."})

        if vehicle.status == Vehicle.Status.UNAVAILABLE:
            raise serializers.ValidationError({"vehicle": f"Vehicle '{vehicle.make_model}' is currently marked unavailable."})

        # Overlap check (Rule 12)
        overlap_qs = Booking.objects.filter(
            vehicle=vehicle,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
            pickup_date__lte=return_date,
            return_date__gte=pickup_date
        )
        if self.instance:
            overlap_qs = overlap_qs.exclude(pk=self.instance.pk)

        if overlap_qs.exists():
            conflict = overlap_qs.first()
            raise serializers.ValidationError({
                "vehicle": f"Vehicle '{vehicle.make_model}' is already booked from {conflict.pickup_date} to {conflict.return_date} (Booking {conflict.booking_id}). Please select another vehicle or different dates."
            })

        # Calculate base_fare if not provided or 0
        if not attrs.get('base_fare') or attrs.get('base_fare') == 0:
            days = (return_date - pickup_date).days + 1
            days = max(1, days)
            attrs['base_fare'] = days * vehicle.per_day_rate

        return attrs

    def create(self, validated_data):
        customer = validated_data.get('customer')
        cust_name = validated_data.pop('customer_name', '').strip()
        cust_phone = validated_data.pop('customer_phone', '').strip()
        cust_email = validated_data.pop('customer_email', '').strip()

        request = self.context.get('request')

        # If customer not linked, resolve or create customer
        if not customer:
            user = request.user if request and request.user.is_authenticated else None
            if user:
                customer, _ = Customer.objects.get_or_create(
                    user=user,
                    defaults={
                        'name': cust_name or user.full_name,
                        'email': cust_email or user.email,
                        'phone': cust_phone or user.phone,
                        'address': user.address
                    }
                )
            elif cust_phone:
                customer, _ = Customer.objects.get_or_create(
                    phone=cust_phone,
                    defaults={
                        'name': cust_name or 'Valued Customer',
                        'email': cust_email,
                    }
                )
            else:
                customer = Customer.objects.create(
                    name=cust_name or 'Valued Customer',
                    email=cust_email,
                    phone=cust_phone or '0000000000'
                )
            validated_data['customer'] = customer

        booking = super().create(validated_data)

        # Automatically generate invoice in billing app for this booking
        try:
            from billing.models import Invoice
            from datetime import timedelta
            from django.conf import settings
            tax_rate = getattr(settings, 'TAX_RATE', 0.05)
            taxable = booking.base_fare
            tax_amount = round(float(taxable) * float(tax_rate), 2)
            grand_total = float(taxable) + tax_amount

            Invoice.objects.get_or_create(
                booking=booking,
                defaults={
                    'customer': booking.customer,
                    'vehicle': booking.vehicle,
                    'issue_date': booking.pickup_date,
                    'due_date': booking.pickup_date + timedelta(days=3),
                    'base_fare': booking.base_fare,
                    'discount': 0,
                    'taxable_amount': taxable,
                    'tax_rate': tax_rate,
                    'tax_amount': tax_amount,
                    'grand_total': grand_total,
                    'payment_status': Invoice.PaymentStatus.UNPAID,
                }
            )
        except Exception:
            pass

        return booking
