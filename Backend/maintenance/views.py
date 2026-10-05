from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import WorkOrder
from .serializers import WorkOrderSerializer
from accounts.permissions import ReadOnlyOrStaffAdmin
from vehicles.models import Vehicle


class WorkOrderViewSet(viewsets.ModelViewSet):
    queryset = WorkOrder.objects.select_related('vehicle').all()
    serializer_class = WorkOrderSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = [
        'work_order_id', 'vehicle__make_model', 'vehicle__registration_number',
        'service_type', 'issue_description', 'garage_name'
    ]
    ordering_fields = ['scheduled_date', 'estimated_cost', 'actual_cost', 'priority']
    ordering = ['-scheduled_date']

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get('status')
        if status_param and status_param.lower() != 'all':
            qs = qs.filter(status__iexact=status_param)
        return qs

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def start_service(self, request, pk=None):
        wo = self.get_object()
        wo.status = WorkOrder.Status.IN_SERVICE
        wo.save()
        return Response({
            'message': f'Work order {wo.work_order_id} marked as In Service.',
            'work_order': WorkOrderSerializer(wo).data
        })

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def complete_service(self, request, pk=None):
        wo = self.get_object()
        actual = request.data.get('actual_cost')
        if actual is not None:
            try:
                wo.actual_cost = float(actual)
            except ValueError:
                pass
        wo.status = WorkOrder.Status.COMPLETED
        wo.completion_date = timezone.now().date()
        wo.save()
        return Response({
            'message': f'Work order {wo.work_order_id} marked as Completed.',
            'work_order': WorkOrderSerializer(wo).data
        })
