import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aData = await _api.getAnalytics();
      final sData = await _api.getDashboardSummary();
      if (mounted) {
        setState(() {
          _analytics = aData;
          _summary = sData;
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
    final kpis = _analytics?['kpis'] ?? {};
    final f = _summary?['financials'] ?? {};
    final v = _summary?['vehicles'] ?? {};

    final totalRev = f['total_revenue'] ?? (kpis['total_revenue'] ?? 0);
    final totalBookings = kpis['total_bookings'] ?? 0;
    final activeCustomers = kpis['active_customers'] ?? 0;
    final fleetTotal = v['total'] ?? 0;
    final fleetOnTrip = v['on_trip'] ?? 0;
    final utilization = fleetTotal > 0 ? ((fleetOnTrip / fleetTotal) * 100).toStringAsFixed(1) : '0.0';

    final monthly = (_analytics?['monthly_trends'] as List?) ?? [];
    final topVehicles = (_analytics?['top_vehicles'] as List?) ?? [];
    final topDrivers = (_analytics?['top_drivers'] as List?) ?? [];

    return Scaffold(
      appBar: TamsAppBar(
        title: 'Reports & Analytics',
        onRefresh: _loadReports,
      ),
      drawer: const TamsDrawer(currentRoute: 'Reports & Analytics'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Calculating aggregations from PostgreSQL...')
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _loadReports)
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Grid
                        GridView(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: MediaQuery.of(context).size.width < 360 ? 116 : 110,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            StatCard(
                              title: 'Total Revenue',
                              value: AppTheme.formatCurrency(totalRev),
                              subtext: 'From verified payments',
                              icon: Icons.currency_rupee,
                              iconColor: AppTheme.success,
                            ),
                            StatCard(
                              title: 'Total Reservations',
                              value: totalBookings.toString(),
                              subtext: 'Lifetime bookings',
                              icon: Icons.calendar_month,
                              iconColor: AppTheme.accent,
                            ),
                            StatCard(
                              title: 'Fleet In Use',
                              value: '$utilization%',
                              subtext: '$fleetOnTrip on active duty',
                              icon: Icons.pie_chart_outline,
                              iconColor: AppTheme.info,
                            ),
                            StatCard(
                              title: 'Customers',
                              value: activeCustomers.toString(),
                              subtext: 'Registered clients',
                              icon: Icons.people_outline,
                              iconColor: const Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Monthly Trends Table / Cards
                        const Text(
                          '6-MONTH REVENUE & BOOKING TRENDS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (monthly.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: const Center(
                                child: Text('No historical monthly data recorded yet', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                            ),
                          )
                        else
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: monthly.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
                              itemBuilder: (context, index) {
                                final m = monthly[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.date_range, color: AppTheme.primary, size: 20),
                                  title: Text(
                                    m['month'] ?? 'Month',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  subtitle: Text(
                                    '${m['bookings']} bookings completed',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  trailing: Text(
                                    AppTheme.formatCurrency(m['revenue']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Top Vehicles Section
                        if (topVehicles.isNotEmpty) ...[
                          const Text(
                            'MOST POPULAR FLEET VEHICLES',
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
                              itemCount: topVehicles.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
                              itemBuilder: (context, index) {
                                final tv = topVehicles[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.accentSoft,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
                                    ),
                                  ),
                                  title: Text(
                                    tv['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  trailing: Text(
                                    '${tv['trips']} Trips',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Top Drivers Section
                        if (topDrivers.isNotEmpty) ...[
                          const Text(
                            'TOP ACTIVE DRIVERS',
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
                              itemCount: topDrivers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
                              itemBuilder: (context, index) {
                                final td = topDrivers[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.infoSoft,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.info),
                                    ),
                                  ),
                                  title: Text(
                                    td['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  trailing: Text(
                                    '${td['trips']} Trips Completed',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}