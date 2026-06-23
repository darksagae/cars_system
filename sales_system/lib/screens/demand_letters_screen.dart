import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/demand_letter_provider.dart';
import '../models/demand_letter.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'demand_letters/demand_letter_form_screen.dart';
// import 'demand_letters/demand_letter_detail_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart'; // Temporarily disabled

class DemandLettersScreen extends StatefulWidget {
  const DemandLettersScreen({super.key});

  @override
  State<DemandLettersScreen> createState() => _DemandLettersScreenState();
}

class _DemandLettersScreenState extends State<DemandLettersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemandLetters();
    });
  }

  void _loadDemandLetters() {
    Provider.of<DemandLetterProvider>(context, listen: false).loadDemandLetters();
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
                  child: _buildDemandLettersList(),
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
              builder: (context) => const DemandLetterFormScreen(),
            ),
          ).then((_) => _loadDemandLetters());
        },
        backgroundColor: Colors.orange,
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
          FontAwesomeIcons.fileLines,
          size: 32,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Text(
          'Demand Letters',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Consumer<DemandLetterProvider>(
          builder: (context, provider, child) {
            return Text(
              '${provider.demandLetters.length} Letters',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<DemandLetterProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: provider.searchDemandLetters,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search demand letters...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.white,
                      size: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(provider),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton(DemandLetterProvider provider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const FaIcon(
          FontAwesomeIcons.filter,
          color: Colors.white,
          size: 16,
        ),
      ),
      onSelected: (value) {
        if (value == 'all') {
          provider.clearFilters();
        } else {
          provider.filterByStatus(value);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('All Status'),
        ),
        const PopupMenuItem(
          value: 'draft',
          child: Text('Draft'),
        ),
        const PopupMenuItem(
          value: 'sent',
          child: Text('Sent'),
        ),
        const PopupMenuItem(
          value: 'acknowledged',
          child: Text('Acknowledged'),
        ),
        const PopupMenuItem(
          value: 'resolved',
          child: Text('Resolved'),
        ),
        const PopupMenuItem(
          value: 'escalated',
          child: Text('Escalated'),
        ),
      ],
    );
  }

  Widget _buildDemandLettersList() {
    return Consumer<DemandLetterProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (provider.demandLetters.isEmpty) {
          return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                  FontAwesomeIcons.fileLines,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Demand Letters',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first demand letter',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.demandLetters.length,
          itemBuilder: (context, index) {
            final letter = provider.demandLetters[index];
            return _buildDemandLetterCard(letter);
          },
        );
      },
    );
  }

  Widget _buildDemandLetterCard(DemandLetter letter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _buildComingSoonDialog(),
              ),
            ).then((_) => _loadDemandLetters());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            letter.letterNumber,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            letter.subject,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(letter.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.calendar,
                        'Issue Date',
                        UgandaFormatters.formatDate(letter.issueDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.clock,
                        'Due Date',
                        UgandaFormatters.formatDate(letter.dueDate),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.dollarSign,
                        'Amount',
                        UgandaFormatters.formatCurrency(letter.amount),
                      ),
                    ),
                  ],
                ),
                if (letter.daysOverdue > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${letter.daysOverdue} days overdue',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 12,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(DemandLetterStatus status) {
    Color statusColor;
    switch (status) {
      case DemandLetterStatus.draft:
        statusColor = Colors.grey;
        break;
      case DemandLetterStatus.sent:
        statusColor = GlassLiquidTheme.accentBlue;
        break;
      case DemandLetterStatus.acknowledged:
        statusColor = Colors.orange;
        break;
      case DemandLetterStatus.resolved:
        statusColor = Colors.green;
        break;
      case DemandLetterStatus.escalated:
        statusColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildComingSoonDialog() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Coming Soon',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.hammer,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 24),
                Text(
                  'Demand Letter Details',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature is under development and will be available soon.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassLiquidTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}