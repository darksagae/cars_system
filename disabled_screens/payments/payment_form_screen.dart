
class PaymentFormScreen extends StatefulWidget {
  final Payment? payment;

  const PaymentFormScreen({super.key, this.payment});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  PaymentStatus _status = PaymentStatus.completed;
  PaymentMethod _method = PaymentMethod.cash;
  int? _selectedInvoiceId;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.payment != null;
    if (_isEdit) {
      _populateFields();
    }
  }

  void _populateFields() {
    final payment = widget.payment!;
    _amountController.text = payment.amount.toString();
    _referenceNumberController.text = payment.referenceNumber;
    _notesController.text = payment.notes;
    _paymentDate = payment.paymentDate;
    _status = payment.status;
    _method = payment.method;
    _selectedInvoiceId = payment.invoiceId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpeg'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInvoiceSelection(),
                          const SizedBox(height: 24),
                          _buildPaymentDetails(),
                          const SizedBox(height: 24),
                          _buildPaymentMethod(),
                          const SizedBox(height: 24),
                          _buildNotes(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEdit ? 'Edit Payment' : 'Record New Payment',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice Selection',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<InvoiceProvider>(
          builder: (context, invoiceProvider, child) {
            return DropdownButtonFormField<int>(
              value: _selectedInvoiceId,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              dropdownColor: Colors.grey[900],
              style: GoogleFonts.poppins(color: Colors.white),
              hint: Text(
                'Select Invoice',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              items: invoiceProvider.invoices.map((invoice) {
                return DropdownMenuItem<int>(
                  value: invoice.id,
                  child: Text(
                    '${invoice.invoiceNumber} - \$${invoice.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInvoiceId = value;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _amountController,
                label: 'Amount',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Payment Date',
                value: _paymentDate,
                onChanged: (date) => setState(() => _paymentDate = date!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _referenceNumberController,
          label: 'Reference Number',
          hint: 'Payment reference or transaction ID',
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                label: 'Method',
                value: _method,
                items: PaymentMethod.values,
                onChanged: (value) => setState(() => _method = value!),
                itemBuilder: (method) => method.name.toUpperCase(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Status',
                value: _status,
                items: PaymentStatus.values,
                onChanged: (value) => setState(() => _status = value!),
                itemBuilder: (status) => status.name.toUpperCase(),
              ),
            ),
          ],
        ),
