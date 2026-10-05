from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import Customer, Booking
from .serializers import CustomerSerializer, BookingSerializer
from accounts.permissions import IsStaffOrAdminUser, ReadOnlyOrStaffAdmin


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'phone', 'email']

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and (user.role in ['ADMIN', 'STAFF'] or user.is_superuser):
            return Customer.objects.all()
        # Customer only sees their own profile
        return Customer.objects.filter(user=user)


class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.select_related('customer', 'vehicle').all()
    serializer_class = BookingSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = [
        'booking_id', 'customer__name', 'customer__phone',
        'vehicle__make_model', 'vehicle__registration_number',
        'pickup_location', 'destination_location'
    ]
    ordering_fields = ['pickup_date', 'return_date', 'base_fare', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        # If logged in as customer, filter to customer's own bookings
        if user.is_authenticated and user.role == 'CUSTOMER':
            qs = qs.filter(Q(customer__user=user) | Q(customer__email__iexact=user.email))

        # Filters
        b_status = self.request.query_params.get('status')
        if b_status and b_status.lower() != 'all':
            qs = qs.filter(status__iexact=b_status)

        customer_name = self.request.query_params.get('customer')
        if customer_name:
            qs = qs.filter(customer__name__icontains=customer_name)

        return qs

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def my_bookings(self, request):
        user = request.user
        customer_name = request.query_params.get('customer_name')
        qs = self.get_queryset()

        if user.is_authenticated and user.role == 'CUSTOMER':
            qs = qs.filter(Q(customer__user=user) | Q(customer__email__iexact=user.email))
        elif customer_name:
            qs = qs.filter(customer__name__icontains=customer_name.strip())

        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        if booking.status == Booking.Status.COMPLETED:
            return Response(
                {'error': 'A completed booking cannot be cancelled.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        booking.status = Booking.Status.CANCELLED
        booking.save()

        # Cancel corresponding invoice if unpaid
        try:
            from billing.models import Invoice
            if hasattr(booking, 'invoice') and booking.invoice.payment_status != Invoice.PaymentStatus.PAID:
                booking.invoice.payment_status = Invoice.PaymentStatus.CANCELLED
                booking.invoice.save()
        except Exception:
            pass

        return Response({
            'message': f'Booking {booking.booking_id} has been cancelled successfully.',
            'booking': BookingSerializer(booking).data
        })

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def accept(self, request, pk=None):
        booking = self.get_object()
        if booking.status == Booking.Status.CANCELLED:
            return Response(
                {'error': 'A cancelled booking cannot be accepted. Please create a new booking.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        driver_id = request.data.get('driver_id')
        time_val = request.data.get('time', '08:00 AM')
        payout_val = request.data.get('payout', 0)
        remarks_val = request.data.get('remarks', '')

        driver = None
        duty_slip = None

        if driver_id:
            try:
                from drivers.models import Driver
                from duty_slips.models import DutySlip
                from django.utils import timezone
                driver = Driver.objects.get(pk=driver_id)
            except Exception:
                return Response(
                    {'error': f'Driver with ID {driver_id} was not found.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Check driver license expiry
            if driver.license_expiry < timezone.now().date():
                return Response(
                    {'error': f"Driver {driver.name}'s license expired on {driver.license_expiry}. Cannot assign expired driver."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Check if driver status is Inactive or On Leave
            if driver.status in [Driver.Status.INACTIVE, Driver.Status.ON_LEAVE]:
                return Response(
                    {'error': f"Driver {driver.name} is currently {driver.status}. Cannot assign to trip."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Check driver overlap for overlapping dates
            overlap = DutySlip.objects.filter(
                driver=driver,
                status__in=[DutySlip.Status.UPCOMING, DutySlip.Status.IN_PROGRESS],
                date__gte=booking.pickup_date,
                date__lte=booking.return_date
            ).exclude(booking=booking).first()

            if overlap:
                return Response(
                    {'error': f"Driver {driver.name} is already assigned to Duty Slip {overlap.slip_id} on {overlap.date}. Please choose another driver."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create or update DutySlip
            duty_slip = DutySlip.objects.filter(booking=booking).first()
            if not duty_slip:
                duty_slip = DutySlip.objects.create(
                    booking=booking,
                    driver=driver,
                    vehicle=booking.vehicle,
                    date=booking.pickup_date,
                    time=time_val or '08:00 AM',
                    pickup=booking.pickup_location,
                    destination=booking.destination_location,
                    customer_name=booking.customer.name,
                    customer_phone=booking.customer.phone,
                    payout=payout_val or 0,
                    remarks=remarks_val or f'Duty slip created on booking acceptance for {booking.booking_id}',
                    status=DutySlip.Status.UPCOMING
                )
            else:
                duty_slip.driver = driver
                duty_slip.vehicle = booking.vehicle
                duty_slip.date = booking.pickup_date
                if time_val:
                    duty_slip.time = time_val
                if payout_val is not None:
                    duty_slip.payout = payout_val
                if remarks_val:
                    duty_slip.remarks = remarks_val
                duty_slip.save()

        # Update booking status to Confirmed
        booking.status = Booking.Status.CONFIRMED
        booking.save()

        message = f'Booking {booking.booking_id} accepted successfully.'
        if driver and duty_slip:
            message += f' Driver {driver.name} assigned with Duty Slip {duty_slip.slip_id}.'

        return Response({
            'message': message,
            'booking': BookingSerializer(booking).data
        })

