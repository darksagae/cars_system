import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import '../providers/customer_provider.dart';
import '../providers/theme_provider.dart';
import '../models/customer.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';
import '../services/auth_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  int? _hoveredIndex;
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildCustomersList(),
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
                  builder: (context) => const CustomerFormScreen(),
                ),
              ).then((_) => _loadCustomers());
            },
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const FaIcon(
              FontAwesomeIcons.plus,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.people,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              'Customers',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${customerProvider.customers.length} customers',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
            onChanged: (value) => customerProvider.searchCustomers(value),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search customers...',
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
        );
      },
    );
  }

  Widget _buildCustomersList() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        if (customerProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (customerProvider.customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.users,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No customers found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
            Text(
                  'Add your first customer to get started',
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
          itemCount: customerProvider.customers.length,
          itemBuilder: (context, index) {
            final customer = customerProvider.customers[index];
            return _buildCustomerCard(customer);
          },
        );
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final index = Provider.of<CustomerProvider>(context, listen: false).customers.indexOf(customer);
    final isHover = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerDetailScreen(customer: customer),
              ),
            ).then((_) => _loadCustomers());
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
                    color: isHover ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipOval(
                    child: customer.profileImage != null && customer.profileImage!.isNotEmpty
                        ? Image.file(
                            File(customer.profileImage!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.user,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.user,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHover ? Colors.black : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isHover ? Colors.black87 : Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.phone,
                              size: 12,
                              color: isHover ? Colors.black54 : Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer.phone,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isHover ? Colors.black54 : Colors.white60,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (customer.company.isNotEmpty) ...[
                        const SizedBox(height: 4),
                          Text(
                          customer.company,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                              color: isHover ? Colors.black54 : Colors.white60,
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
                        color: customer.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer.isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: customer.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      UgandaFormatters.formatCurrency(customer.totalSpent),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHover ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<bool>(
                          future: AuthService().isCurrentUserAdmin(),
                          builder: (context, snap) {
                            if (!(snap.data ?? false)) return const SizedBox.shrink();
                            return IconButton(
                              tooltip: 'Delete customer',
                              icon: const FaIcon(FontAwesomeIcons.trash, size: 16, color: Colors.redAccent),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete customer'),
                                    content: Text('Are you sure you want to delete "${customer.name}"? This cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final provider = Provider.of<CustomerProvider>(context, listen: false);
                                  final ok = await provider.deleteCustomer(customer.id!);
                                  if (!mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Customer deleted'), backgroundColor: Colors.green),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to delete customer'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ],
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
}
