import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';
import 'booking_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final ApiService _api = ApiService();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
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

  Future<void> _cancelBooking(BookingModel b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking ${b.bookingId}?'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.cancelBooking(b.id);
      _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking ${b.bookingId} cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedStatus == 'All'
        ? _bookings
        : _bookings.where((b) => b.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();

    return Scaffold(
      appBar: TamsAppBar(
        title: 'My Bookings',
        onRefresh: _loadBookings,
      ),
      drawer: const TamsDrawer(currentRoute: 'My Bookings'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book Car', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage()));
        },
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((st) {
                  final isSel = _selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: isSel,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppTheme.textDark,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedStatus = st);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Retrieving your bookings from PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadBookings)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.calendar_month_outlined,
                            title: 'No Bookings Found',
                            description: 'You have no bookings matching this status.',
                            actionText: 'Book a Car Now',
                            onAction: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage()));
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final b = filtered[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                b.bookingId,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge(status: b.status),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.route, size: 16, color: AppTheme.accent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${b.pickupLocation} → ${b.destinationLocation}',
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
                                                Text('${b.vehicleName}${b.vehicleRegistration.isNotEmpty ? ' (${b.vehicleRegistration})' : ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text('${b.pickupDate} to ${b.returnDate}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (b.assignedDriverName != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success.withValues(alpha: 0.09),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person_pin, size: 15, color: AppTheme.success),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Driver: ${b.assignedDriverName}${b.assignedDriverPhone != null ? ' (${b.assignedDriverPhone})' : ''}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.success),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              'Total Fare: ${AppTheme.formatCurrency(b.baseFare)}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.accentDark),
                                            ),
                                            if (b.status != 'Completed' && b.status != 'Cancelled')
                                              TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                icon: const Icon(Icons.cancel_outlined, size: 14, color: AppTheme.danger),
                                                label: const Text('Cancel Booking', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                                                onPressed: () => _cancelBooking(b),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}