from rest_framework import serializers
from .models import WorkOrder
from vehicles.models import Vehicle


class WorkOrderSerializer(serializers.ModelSerializer):
    vehicle_id = serializers.PrimaryKeyRelatedField(
        queryset=Vehicle.objects.all(),
        source='vehicle',
        write_only=True,
        required=True
    )
    vehicle_name = serializers.CharField(source='vehicle.make_model', read_only=True)
    vehicle_reg = serializers.CharField(source='vehicle.registration_number', read_only=True)

    class Meta:
        model = WorkOrder
        fields = [
            'id', 'work_order_id', 'vehicle_id', 'vehicle_name', 'vehicle_reg',
            'service_type', 'issue_description', 'priority',
            'garage_name', 'estimated_cost', 'actual_cost',
            'scheduled_date', 'completion_date', 'status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'work_order_id', 'created_at', 'updated_at']
