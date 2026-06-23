
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/demand_letter.dart';
import '../../providers/demand_letter_provider.dart';
import '../../widgets/glass_container.dart';
import 'demand_letter_form_screen.dart';
import 'demand_letter_detail_screen.dart';

class DemandLettersScreen extends StatefulWidget {
  const DemandLettersScreen({super.key});

  @override
  State<DemandLettersScreen> createState() => _DemandLettersScreenState();
}

class _DemandLettersScreenState extends State<DemandLettersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterStatus;
  DemandLetterTemplate? _filterTemplate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemandLetterProvider>().loadDemandLetters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 24),
          _buildDemandLettersList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demand Letters',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<DemandLetterProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.demandLetters.length} demand letters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                );
              },
            ),
          ],
        ),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCreateDemandLetterDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Letter',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                context.read<DemandLetterProvider>().searchDemandLetters(value);
              },
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search demand letters...',
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
        ),
        const SizedBox(width: 16),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showStatusFilterDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.filter,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _filterStatus?.toUpperCase() ?? 'ALL',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTemplateFilterDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.fileLines,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _filterTemplate?.name.toUpperCase() ?? 'ALL',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandLettersList() {
    return Expanded(
      child: Consumer<DemandLetterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.demandLetters.isEmpty) {
            return GlassContainer(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.fileLines,
                      color: Colors.white.withOpacity(0.4),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No demand letters found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first demand letter to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.demandLetters.length,
            itemBuilder: (context, index) {
              final demandLetter = provider.demandLetters[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildDemandLetterCard(demandLetter),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDemandLetterCard(DemandLetter demandLetter) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDemandLetterDetail(demandLetter),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(demandLetter.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  _getTemplateIcon(demandLetter.status),
                  color: _getStatusColor(demandLetter.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demandLetter.letterNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demandLetter.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${_formatDate(demandLetter.dueDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${demandLetter.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(demandLetter.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      demandLetter.statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStatusColor(demandLetter.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(demandLetter.urgencyLevel).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      demandLetter.urgencyLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _getUrgencyColor(demandLetter.urgencyLevel),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                icon: FaIcon(
                  FontAwesomeIcons.ellipsisVertical,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                onSelected: (value) => _handleMenuAction(value, demandLetter),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.eye, size: 14),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.pen, size: 14),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'send',
                    child: Row(
