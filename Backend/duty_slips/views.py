from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import DutySlip
from .serializers import DutySlipSerializer
from accounts.permissions import ReadOnlyOrStaffAdmin
from vehicles.models import Vehicle
from drivers.models import Driver
from bookings.models import Booking


class DutySlipViewSet(viewsets.ModelViewSet):
    queryset = DutySlip.objects.select_related('booking', 'driver', 'vehicle').all()
    serializer_class = DutySlipSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = [
        'slip_id', 'booking__booking_id', 'driver__name', 'driver__driver_id',
        'vehicle__make_model', 'vehicle__registration_number',
        'customer_name', 'pickup', 'destination'
    ]
    ordering_fields = ['date', 'time', 'payout', 'created_at']
    ordering = ['-date', '-created_at']

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        # If driver logged in, filter to their slips
        if user.is_authenticated and user.role == 'DRIVER':
            qs = qs.filter(Q(driver__user=user) | Q(driver__email__iexact=user.email))

        status_param = self.request.query_params.get('status')
        if status_param and status_param.lower() != 'all':
            qs = qs.filter(status__iexact=status_param)

        driver_id = self.request.query_params.get('driver')
        if driver_id:
            qs = qs.filter(driver__id=driver_id)

        return qs

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def my_slips(self, request):
        user = request.user
        driver_name = request.query_params.get('driver_name')
        qs = self.get_queryset()

        if user.is_authenticated and user.role == 'DRIVER':
            qs = qs.filter(Q(driver__user=user) | Q(driver__email__iexact=user.email))
        elif driver_name:
            qs = qs.filter(driver__name__icontains=driver_name.strip())

        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def start_trip(self, request, pk=None):
        slip = self.get_object()
        start_km = request.data.get('start_odometer')
        if start_km is not None:
            try:
                slip.start_odometer = int(start_km)
            except ValueError:
                return Response({'error': 'Start odometer must be a valid integer.'}, status=status.HTTP_400_BAD_REQUEST)

        slip.status = DutySlip.Status.IN_PROGRESS
        slip.save()

        # Update vehicle and driver status
        if slip.vehicle:
            slip.vehicle.status = Vehicle.Status.ON_TRIP
            slip.vehicle.save()
        if slip.driver:
            slip.driver.status = Driver.Status.ON_DUTY
            slip.driver.save()

        return Response({
            'message': f'Trip {slip.slip_id} started successfully.',
            'duty_slip': DutySlipSerializer(slip).data
        })

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def complete_trip(self, request, pk=None):
        slip = self.get_object()
        end_km = request.data.get('end_odometer')

        if end_km is not None:
            try:
                end_km = int(end_km)
                if slip.start_odometer and end_km < slip.start_odometer:
                    return Response({
                        'error': f'End odometer ({end_km} km) cannot be less than start odometer ({slip.start_odometer} km).'
                    }, status=status.HTTP_400_BAD_REQUEST)
                slip.end_odometer = end_km
            except ValueError:
                return Response({'error': 'End odometer must be a valid integer.'}, status=status.HTTP_400_BAD_REQUEST)

        slip.status = DutySlip.Status.COMPLETED
        slip.save()

        # Update vehicle and driver back to Available
        if slip.vehicle:
            slip.vehicle.status = Vehicle.Status.AVAILABLE
            slip.vehicle.save()
        if slip.driver:
            slip.driver.status = Driver.Status.AVAILABLE
            slip.driver.save()

        # Mark linked booking as completed
        if slip.booking:
            slip.booking.status = Booking.Status.COMPLETED
            slip.booking.save()

        return Response({
            'message': f'Trip {slip.slip_id} marked as completed.',
            'duty_slip': DutySlipSerializer(slip).data
        })
