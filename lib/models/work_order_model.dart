class WorkOrderModel {
  final int id;
  final String workOrderId;
  final int? vehicleId;
  final String vehicleName;
  final String vehicleReg;
  final String serviceType;
  final String issueDescription;
  final String priority; // Normal, High, Urgent
  final String garageName;
  final double estimatedCost;
  final double actualCost;
  final String scheduledDate;
  final String? completionDate;
  final String status; // Scheduled, In Service, Completed, Cancelled

  WorkOrderModel({
    required this.id,
    required this.workOrderId,
    this.vehicleId,
    required this.vehicleName,
    required this.vehicleReg,
    required this.serviceType,
    required this.issueDescription,
    this.priority = 'Normal',
    this.garageName = '',
    this.estimatedCost = 0.0,
    this.actualCost = 0.0,
    required this.scheduledDate,
    this.completionDate,
    required this.status,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    return WorkOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      workOrderId: json['work_order_id'] ?? '',
      vehicleId: json['vehicle_id'] is int ? json['vehicle_id'] : int.tryParse(json['vehicle_id']?.toString() ?? ''),
      vehicleName: json['vehicle_name'] ?? '',
      vehicleReg: json['vehicle_reg'] ?? '',
      serviceType: json['service_type'] ?? '',
      issueDescription: json['issue_description'] ?? '',
      priority: json['priority'] ?? 'Normal',
      garageName: json['garage_name'] ?? '',
      estimatedCost: json['estimated_cost'] != null ? double.tryParse(json['estimated_cost'].toString()) ?? 0.0 : 0.0,
      actualCost: json['actual_cost'] != null ? double.tryParse(json['actual_cost'].toString()) ?? 0.0 : 0.0,
      scheduledDate: json['scheduled_date'] ?? '',
      completionDate: json['completion_date'],
      status: json['status'] ?? 'Scheduled',
    );
  }
}
