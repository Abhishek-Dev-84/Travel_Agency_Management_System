import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/invoice_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_tile.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';

import 'search_page.dart';
import 'booking_page.dart';
import 'my_booking_page.dart';
import 'invoice_page.dart';
import 'profile_page.dart';
import 'demo_payment_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final ApiService _api = ApiService();

  List<BookingModel> _myBookings = [];
  List<InvoiceModel> _myInvoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bFuture = _api.getMyBookings();
      final iFuture = _api.getMyInvoices();
      final bookings = await bFuture;
      final invoices = await iFuture;

      if (mounted) {
        setState(() {
          _myBookings = bookings;
          _myInvoices = invoices;
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
    final user = AuthService().user;
    final userName = user?.fullName ?? (user?.username ?? 'Customer');
    final unpaidInvoices = _myInvoices.where((i) => i.paymentStatus == 'Unpaid').toList();

    return Scaffold(
      appBar: TamsAppBar(
        title: 'Customer Portal',
        onRefresh: _loadDashboardData,
      ),
      drawer: const TamsDrawer(currentRoute: 'Dashboard'),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading bookings & invoices...')
          : _errorMessage != null
              ? ErrorView(message: _errorMessage!, onRetry: _loadDashboardData)
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: AppTheme.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hello, $userName! 👋',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Where would you like to travel next?',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Book Now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Unpaid Invoice Notice
                        if (unpaidInvoices.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warningSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.notification_important_outlined, color: AppTheme.warning, size: 22),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unpaid Invoice: ${unpaidInvoices.first.invoiceId}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                        ),
                                        Text(
                                          'Due: ${AppTheme.formatCurrency(unpaidInvoices.first.grandTotal)} (Includes 5% GST)',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.warning,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => DemoPaymentPage(invoice: unpaidInvoices.first)),
                                    );
                                    if (res == true) _loadDashboardData();
                                  },
                                  child: const Text('Pay Demo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Quick Navigation Grid
                        const Text(
                          'EXPLORE SERVICES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: MediaQuery.sizeOf(context).width < 360 ? 112 : 118,
                          ),
                          children: [
                            DashboardTile(
                              title: 'Search Fleet',
                              subtitle: 'Browse available vehicles',
                              icon: Icons.search,
                              iconColor: AppTheme.info,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                            ),
                            DashboardTile(
                              title: 'Reserve Vehicle',
                              subtitle: 'Instant booking with fare',
                              icon: Icons.car_rental,
                              iconColor: AppTheme.accent,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                            ),
                            DashboardTile(
                              title: 'My Bookings',
                              subtitle: '${_myBookings.length} total reservations',
                              icon: Icons.calendar_month,
                              iconColor: const Color(0xFF8B5CF6),
                              badge: _myBookings.isNotEmpty ? '${_myBookings.length}' : null,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsPage())),
                            ),
                            DashboardTile(
                              title: 'My Invoices',
                              subtitle: '${_myInvoices.length} billing statements',
                              icon: Icons.receipt_long,
                              iconColor: AppTheme.success,
                              badge: unpaidInvoices.isNotEmpty ? '${unpaidInvoices.length} Due' : null,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicePage())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Latest Booking Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MY LATEST RESERVATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (_myBookings.isNotEmpty)
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsPage())),
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

                        if (_myBookings.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.car_rental_outlined, size: 40, color: AppTheme.textMuted),
                                    const SizedBox(height: 8),
                                    const Text('No Bookings Yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    const Text('Ready to travel? Search our fleet and reserve a vehicle.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
                                    const SizedBox(height: 14),
                                    ElevatedButton(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
                                      child: const Text('Reserve Vehicle'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _myBookings.first.bookingId,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary),
                                      ),
                                      StatusBadge(status: _myBookings.first.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.route, size: 16, color: AppTheme.accent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${_myBookings.first.pickupLocation} → ${_myBookings.first.destinationLocation}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.directions_car, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_myBookings.first.vehicleName} (${_myBookings.first.vehicleRegistration})',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.date_range, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_myBookings.first.pickupDate} to ${_myBookings.first.returnDate}',
                                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1, color: AppTheme.border),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Estimated Fare: ${AppTheme.formatCurrency(_myBookings.first.baseFare)}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.accentDark),
                                      ),
                                      Text(
                                        '${_myBookings.first.durationDays} day(s)',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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