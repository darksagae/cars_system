enum InvoiceType {
  carSale,           // Regular car sale
  clearanceService,  // Clearance service from Mombasa
  custom,            // Custom invoice
  quotation,         // Quotation
  invoice,           // Invoice
}

extension InvoiceTypeExtension on InvoiceType {
  String get displayName {
    switch (this) {
      case InvoiceType.carSale:
        return 'Car Sale';
      case InvoiceType.clearanceService:
        return 'Clearance Service';
      case InvoiceType.custom:
        return 'Custom Invoice';
      case InvoiceType.quotation:
        return 'Quotation';
      case InvoiceType.invoice:
        return 'Invoice';
    }
  }
  
  String get description {
    switch (this) {
      case InvoiceType.carSale:
        return 'Full car sale with import taxes and fees';
      case InvoiceType.clearanceService:
        return 'Clearance service from Mombasa to Uganda';
      case InvoiceType.custom:
        return 'Custom invoice for other services';
      case InvoiceType.quotation:
        return 'Price quotation for vehicle';
      case InvoiceType.invoice:
        return 'Official invoice for sale';
    }
  }
}
