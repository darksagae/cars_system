import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'vehicles/vehicle_form_screen.dart';
import 'vehicles/vehicle_detail_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    Provider.of<VehicleProvider>(context, listen: false).loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildVehiclesList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleFormScreen(),
            ),
          ).then((_) => _loadVehicles());
        },
        backgroundColor: Colors.green,
        child: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
          children: [
            Icon(
              FontAwesomeIcons.car,
          size: 32,
          color: Colors.white,
            ),
        const SizedBox(width: 12),
            Text(
              'Vehicle Inventory',
          style: GoogleFonts.poppins(
            fontSize: 28,
                fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${vehicleProvider.vehicles.length} vehicles',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (value) => vehicleProvider.searchVehicles(value),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search vehicles...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  prefixIcon: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VehicleStatus>(
                        value: vehicleProvider.statusFilter,
                        hint: Text(
                          'All Status',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        dropdownColor: Colors.grey[800],
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: [
                          DropdownMenuItem<VehicleStatus>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem<VehicleStatus>(
                            value: VehicleStatus.inStock,
                            child: Text('In Stock'),
                          ),
                          DropdownMenuItem<VehicleStatus>(
                            value: VehicleStatus.outOfStock,
                            child: Text('Out of Stock'),
                          ),
                          DropdownMenuItem<VehicleStatus>(
                            value: VehicleStatus.sold,
                            child: Text('Sold'),
                          ),
                          DropdownMenuItem<VehicleStatus>(
                            value: VehicleStatus.reserved,
                            child: Text('Reserved'),
                          ),
                        ],
                        onChanged: (value) => vehicleProvider.filterByStatus(value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehiclesList() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (vehicleProvider.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.car,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No vehicles in inventory',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first vehicle to get started',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: vehicleProvider.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicleProvider.vehicles[index];
            return _buildVehicleCard(vehicle);
          },
        );
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailScreen(vehicle: vehicle),
              ),
            ).then((_) => _loadVehicles());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.car,
                      color: GlassLiquidTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vehicle.color.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Color: ${vehicle.color}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getVehicleStatusColor(vehicle.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vehicle.status.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getVehicleStatusColor(vehicle.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.formattedPriceUSD,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mileage: ${vehicle.mileage} km',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getVehicleStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inStock:
        return Colors.green;
      case VehicleStatus.outOfStock:
        return Colors.red;
      case VehicleStatus.sold:
        return GlassLiquidTheme.accentBlue;
      case VehicleStatus.reserved:
        return Colors.orange;
    }
  }
}