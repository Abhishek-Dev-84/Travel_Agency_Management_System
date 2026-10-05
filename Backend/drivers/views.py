from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Driver
from .serializers import DriverSerializer
from accounts.permissions import ReadOnlyOrStaffAdmin


class DriverViewSet(viewsets.ModelViewSet):
    queryset = Driver.objects.all()
    serializer_class = DriverSerializer
    permission_classes = [ReadOnlyOrStaffAdmin]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'driver_id', 'phone', 'license_number']
    ordering_fields = ['driver_id', 'name', 'experience_years', 'rating', 'license_expiry']
    ordering = ['driver_id']

    def get_queryset(self):
        qs = super().get_queryset()
        d_status = self.request.query_params.get('status')
        lic_status = self.request.query_params.get('license_status')

        if d_status:
            qs = qs.filter(status__iexact=d_status)

        if lic_status:
            from django.utils import timezone
            from datetime import timedelta
            today = timezone.now().date()
            if lic_status.lower() == 'expired':
                qs = qs.filter(license_expiry__lt=today)
            elif lic_status.lower() in ['expiring soon', 'expiring']:
                qs = qs.filter(license_expiry__gte=today, license_expiry__lte=today + timedelta(days=30))
            elif lic_status.lower() == 'valid':
                qs = qs.filter(license_expiry__gt=today + timedelta(days=30))
        return qs

    @action(detail=False, methods=['get', 'patch'], permission_classes=[permissions.IsAuthenticated])
    def my_profile(self, request):
        driver = Driver.objects.filter(user=request.user).first()
        if not driver:
            # Fallback by email or phone
            driver = Driver.objects.filter(email__iexact=request.user.email).first()
        if not driver:
            return Response({'detail': 'No driver profile linked to this account.'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.method.lower() == 'patch':
            serializer = self.get_serializer(driver, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

        serializer = self.get_serializer(driver)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def update_status(self, request):
        driver = Driver.objects.filter(user=request.user).first() or Driver.objects.filter(email__iexact=request.user.email).first()
        if not driver:
            return Response({'detail': 'No driver profile linked to this account.'}, status=status.HTTP_404_NOT_FOUND)
        new_status = request.data.get('status')
        if new_status:
            driver.status = new_status
            driver.save()
        return Response({'message': f'Status updated to {driver.status}', 'status': driver.status})

