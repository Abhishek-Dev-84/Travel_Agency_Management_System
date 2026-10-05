from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import Vehicle
from .serializers import VehicleSerializer
from accounts.permissions import ReadOnlyOrStaffAdmin


class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.all()
    serializer_class = VehicleSerializer
    permission_classes = [ReadOnlyOrStaffAdmin]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['make_model', 'registration_number', 'vehicle_type', 'fuel_type']
    ordering_fields = ['per_day_rate', 'capacity', 'created_at', 'make_model']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = super().get_queryset()
        v_type = self.request.query_params.get('type')
        v_status = self.request.query_params.get('status')
        min_seats = self.request.query_params.get('seats')

        if v_type:
            qs = qs.filter(vehicle_type__iexact=v_type)
        if v_status:
            qs = qs.filter(status__iexact=v_status)
        if min_seats and min_seats.isdigit():
            qs = qs.filter(capacity__gte=int(min_seats))
        return qs

    @action(detail=True, methods=['get'], permission_classes=[permissions.AllowAny])
    def check_availability(self, request, pk=None):
        vehicle = self.get_object()
        pickup_date = request.query_params.get('pickup_date')
        return_date = request.query_params.get('return_date') or pickup_date

        if vehicle.status == Vehicle.Status.MAINTENANCE:
            return Response({
                'available': False,
                'reason': 'Vehicle is currently under maintenance / in service.'
            })

        if vehicle.status == Vehicle.Status.UNAVAILABLE:
            return Response({
                'available': False,
                'reason': 'Vehicle is currently marked unavailable.'
            })

        if pickup_date:
            try:
                from bookings.models import Booking
                overlap = Booking.objects.filter(
                    vehicle=vehicle,
                    status__in=['PENDING', 'CONFIRMED'],
                    pickup_date__lte=return_date,
                    return_date__gte=pickup_date
                ).exists()
                if overlap:
                    return Response({
                        'available': False,
                        'reason': 'Vehicle is already booked for the selected dates.'
                    })
            except Exception:
                pass

        return Response({
            'available': True,
            'message': 'Vehicle is available for the requested period.'
        })
