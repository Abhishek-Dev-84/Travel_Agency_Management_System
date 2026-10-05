import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

import 'vehicle_management_page.dart';
import 'driver_management_page.dart';
import 'customer_management_page.dart';
import 'manage_booking_page.dart';
import 'duty_slip_page.dart';
import 'invoice_management_page.dart';
import 'maintenance_log_page.dart';
import 'reports_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TamsAppBar(
        title: 'Operations Dashboard',
        onRefresh: _loadDashboard,
      ),
      drawer: const TamsDrawer(currentRoute: 'Dashboard'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Connecting to PostgreSQL database...')
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live KPI Grid
                        _buildKpiGrid(),
                        const SizedBox(height: 20),

                        // Quick Navigation Shortcuts
                        const Text(
                          'QUICK ACTIONS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildQuickActionGrid(),
                        const SizedBox(height: 24),

                        // Recent Bookings
                        _buildRecentBookingsSection(),
                        const SizedBox(height: 24),

                        // Recent Activities
                        _buildRecentActivitiesSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiGrid() {
    final v = _summary?['vehicles'] ?? {};
    final d = _summary?['drivers'] ?? {};
    final b = _summary?['bookings'] ?? {};
    final f = _summary?['revenue'] ?? _summary?['financials'] ?? {};

    final totalVehicles = v['total'] ?? 0;
    final availVehicles = v['available'] ?? 0;
    final totalDrivers = d['total'] ?? 0;
    final availDrivers = d['available'] ?? 0;
    final totalBookings = b['total'] ?? 0;
    final pendingBookings = b['pending'] ?? 0;
    final totalRev = f['total_revenue'] ?? 0;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossCount = screenWidth >= 600 ? 4 : 2;
    final kpiExtent = screenWidth < 360 ? 108.0 : 116.0;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: kpiExtent,
      ),
      children: [
        StatCard(
          title: 'Total Revenue',
          value: AppTheme.formatCurrency(totalRev),
          subtext: 'Paid invoices',
          icon: Icons.currency_rupee,
          iconColor: AppTheme.success,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceManagementPage())),
        ),
        StatCard(
          title: 'Bookings',
          value: totalBookings.toString(),
          subtext: '$pendingBookings pending',
          icon: Icons.calendar_month,
          iconColor: AppTheme.accent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBookingPage())),
        ),
        StatCard(
          title: 'Active Fleet',
          value: '$availVehicles / $totalVehicles',
          subtext: 'Available now',
          icon: Icons.directions_car,
          iconColor: AppTheme.info,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleManagementPage())),
        ),
        StatCard(
          title: 'Drivers',
          value: '$availDrivers / $totalDrivers',
          subtext: 'Available on duty',
          icon: Icons.badge,
          iconColor: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverManagementPage())),
        ),
      ],
    );
  }

  Widget _buildQuickActionGrid() {
    final actions = [
      {'title': 'Fleet', 'icon': Icons.directions_car, 'color': AppTheme.info, 'page': const VehicleManagementPage()},
      {'title': 'Drivers', 'icon': Icons.badge, 'color': const Color(0xFF8B5CF6), 'page': const DriverManagementPage()},
      {'title': 'Customers', 'icon': Icons.people, 'color': AppTheme.primaryLight, 'page': const CustomerManagementPage()},
      {'title': 'Bookings', 'icon': Icons.car_rental, 'color': AppTheme.accent, 'page': const ManageBookingPage()},
      {'title': 'Duty Slips', 'icon': Icons.assignment, 'color': const Color(0xFF0D9488), 'page': const DutySlipPage()},
      {'title': 'Invoices', 'icon': Icons.receipt_long, 'color': AppTheme.success, 'page': const InvoiceManagementPage()},
      {'title': 'Service', 'icon': Icons.build, 'color': AppTheme.danger, 'page': const MaintenanceLogPage()},
      {'title': 'Reports', 'icon': Icons.bar_chart, 'color': const Color(0xFFD97706), 'page': const ReportsPage()},
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossCount = screenWidth >= 800 ? 8 : (screenWidth >= 500 ? 6 : (screenWidth < 340 ? 3 : 4));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 84,
      ),
      itemCount: actions.length,
      itemBuilder: (context, idx) {
        final a = actions[idx];
        final col = a['color'] as Color;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => a['page'] as Widget)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a['icon'] as IconData, size: 19, color: col),
                ),
                const SizedBox(height: 5),
                Text(
                  a['title'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookingsSection() {
    final recent = (_summary?['recent_bookings'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT BOOKINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBookingPage())),
              child: const Text(
                'View All →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                'No bookings recorded yet in PostgreSQL',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length > 5 ? 5 : recent.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = recent[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.car_rental, size: 20, color: AppTheme.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${b['id']} · ${b['customer']}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${b['vehicle']} (${b['pickup_date']})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppTheme.formatCurrency(b['fare']),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(status: b['status']?.toString() ?? 'Pending'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    final acts = (_summary?['recent_activities'] as List?) ?? [];
    if (acts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FLEET TIMELINE & ACTIVITY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: acts.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final a = acts[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: a['color'] == 'green'
                      ? AppTheme.successSoft
                      : (a['color'] == 'red' ? AppTheme.dangerSoft : AppTheme.warningSoft),
                  child: Text(
                    a['icon'] ?? '•',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: a['color'] == 'green'
                          ? AppTheme.success
                          : (a['color'] == 'red' ? AppTheme.danger : AppTheme.warning),
                    ),
                  ),
                ),
                title: Text(
                  a['title'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                subtitle: Text(
                  a['desc'] ?? '',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
                trailing: Text(
                  a['time'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}