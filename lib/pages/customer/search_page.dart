import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tams_app_bar.dart';
import '../../widgets/tams_drawer.dart';
import 'booking_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedType = 'All';

  final List<String> _types = ['All', 'Sedan', 'SUV', 'Hatchback', 'Van'];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _api.getVehicles(status: 'Available', search: _searchCtrl.text);
      if (mounted) {
        setState(() {
          _vehicles = list;
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
    final filtered = _selectedType == 'All'
        ? _vehicles
        : _vehicles.where((v) => v.vehicleType.toLowerCase() == _selectedType.toLowerCase()).toList();

    return Scaffold(
      appBar: TamsAppBar(
        title: 'Search Fleet',
        onRefresh: _loadVehicles,
      ),
      drawer: const TamsDrawer(currentRoute: 'Search Vehicles'),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadVehicles(),
                  decoration: InputDecoration(
                    hintText: 'Search available vehicles by model...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadVehicles();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((t) {
                      final isSel = _selectedType == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: isSel,
                          selectedColor: AppTheme.accent,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textDark,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedType = t);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Vehicle List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Scanning available vehicles in PostgreSQL...')
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadVehicles)
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.directions_car_outlined,
                            title: 'No Available Vehicles',
                            description: 'No fleet vehicles match your search criteria right now.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadVehicles,
                            color: AppTheme.accent,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = filtered[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentSoft,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.directions_car, color: AppTheme.accent, size: 30),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    v.makeModel,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppTheme.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${v.vehicleType} · ${v.fuelType} · ${v.transmission}',
                                                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(status: v.status),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: AppTheme.border),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.event_seat, size: 15, color: AppTheme.textMuted),
                                            const SizedBox(width: 4),
                                            Text('${v.capacity} Seats', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                            const SizedBox(width: 14),
                                            if (v.ac) ...[
                                              const Icon(Icons.ac_unit, size: 15, color: AppTheme.info),
                                              const SizedBox(width: 4),
                                              const Text('AC Included', style: TextStyle(fontSize: 12, color: AppTheme.info, fontWeight: FontWeight.w600)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 12,
                                          runSpacing: 10,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Daily Rate', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                                Text(
                                                  '${AppTheme.formatCurrency(v.perDayRate)}/day',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme.accentDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            CustomButton(
                                              text: 'Reserve Car',
                                              icon: Icons.car_rental,
                                              width: 135,
                                              height: 38,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => BookingPage(preselectedVehicle: v),
                                                  ),
                                                );
                                              },
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