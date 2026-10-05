import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../pages/auth/login_page.dart';

import '../pages/admin/admin_dashboard.dart';
import '../pages/admin/vehicle_management_page.dart';
import '../pages/admin/driver_management_page.dart';
import '../pages/admin/customer_management_page.dart';
import '../pages/admin/manage_booking_page.dart';
import '../pages/admin/duty_slip_page.dart';
import '../pages/admin/invoice_management_page.dart';
import '../pages/admin/maintenance_log_page.dart';
import '../pages/admin/reports_page.dart';

import '../pages/driver/driver_dashboard.dart';
import '../pages/driver/driver_trips_page.dart';
import '../pages/driver/driver_profile_page.dart';

import '../pages/customer/customer_dashboard.dart';
import '../pages/customer/search_page.dart';
import '../pages/customer/booking_page.dart';
import '../pages/customer/my_booking_page.dart';
import '../pages/customer/invoice_page.dart';
import '../pages/customer/profile_page.dart';

class TamsDrawer extends StatelessWidget {
  final String currentRoute;

  const TamsDrawer({super.key, this.currentRoute = ''});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.user;
    final role = auth.role.toUpperCase();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Travel Agency System',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? (user?.username ?? 'TAMS User'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Role-specific navigation list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (role == 'ADMIN' || role == 'STAFF') ...[
                  _navItem(context, 'Dashboard', Icons.dashboard_outlined, const AdminDashboard()),
                  _navItem(context, 'Fleet / Vehicles', Icons.directions_car_outlined, const VehicleManagementPage()),
                  _navItem(context, 'Drivers', Icons.badge_outlined, const DriverManagementPage()),
                  _navItem(context, 'Customers', Icons.people_outline, const CustomerManagementPage()),
                  _navItem(context, 'Bookings', Icons.calendar_month_outlined, const ManageBookingPage()),
                  _navItem(context, 'Duty Slips', Icons.assignment_outlined, const DutySlipPage()),
                  _navItem(context, 'Billing & Invoices', Icons.receipt_long_outlined, const InvoiceManagementPage()),
                  _navItem(context, 'Maintenance', Icons.build_outlined, const MaintenanceLogPage()),
                  _navItem(context, 'Reports & Analytics', Icons.bar_chart_outlined, const ReportsPage()),
                ] else if (role == 'DRIVER') ...[
                  _navItem(context, 'Dashboard', Icons.dashboard_outlined, const DriverDashboard()),
                  _navItem(context, 'My Trips & Duty Slips', Icons.route_outlined, const DriverTripsPage()),
                  _navItem(context, 'My Profile', Icons.person_outline, const DriverProfilePage()),
                ] else ...[
                  // CUSTOMER
                  _navItem(context, 'Dashboard', Icons.dashboard_outlined, const CustomerDashboard()),
                  _navItem(context, 'Search Vehicles', Icons.search_outlined, const SearchPage()),
                  _navItem(context, 'Book a Vehicle', Icons.car_rental_outlined, const BookingPage()),
                  _navItem(context, 'My Bookings', Icons.book_online_outlined, const MyBookingsPage()),
                  _navItem(context, 'Invoices & Payments', Icons.receipt_outlined, const InvoicePage()),
                  _navItem(context, 'My Profile', Icons.person_outline, const ProfilePage()),
                ],
              ],
            ),
          ),

          // Drawer Footer / Logout
          const Divider(height: 1, color: AppTheme.border),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String title, IconData icon, Widget targetPage) {
    final isSelected = currentRoute == title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AppTheme.accent : AppTheme.textDark,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.accentDark : AppTheme.textDark,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => targetPage),
            );
          }
        },
      ),
    );
  }
}
