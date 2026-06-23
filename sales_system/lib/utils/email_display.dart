/// Emails auto-generated when the user skips email (e.g. invoice/customer flows).
bool isRealCustomerEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  final lower = email.trim().toLowerCase();
  if (lower == 'noemail@customer.local') return false;
  if (lower.contains('noemail@')) return false;
  if (lower.startsWith('noemail')) return false;
  return true;
}

/// Use in UI lists and detail headers instead of raw [email].
String displayEmailOrNa(String? email) {
  return isRealCustomerEmail(email) ? email!.trim() : 'N/A';
}
