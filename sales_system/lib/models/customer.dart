class Customer {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String location; // For quotation (e.g., "Kampala", "Mukono")
  final String company;
  final String notes;
  final String profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalSpent;
  final int totalInvoices;
  final double balance;
  final bool isActive;

  Customer({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    this.city = '',
    this.location = '',
    this.company = '',
    this.notes = '',
    this.profileImage = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.totalSpent = 0.0,
    this.totalInvoices = 0,
    this.balance = 0.0,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Customer to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'location': location,
      'company': company,
      'notes': notes,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'totalSpent': totalSpent,
      'totalInvoices': totalInvoices,
      'balance': balance,
      'isActive': isActive ? 1 : 0, // Convert boolean to integer
    };
  }

  // Create Customer from Map (database retrieval)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      location: map['location'] ?? '',
      company: map['company'] ?? '',
      notes: map['notes'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      totalSpent: map['totalSpent']?.toDouble() ?? 0.0,
      totalInvoices: map['totalInvoices'] ?? 0,
      balance: map['balance']?.toDouble() ?? 0.0,
      isActive: (map['isActive'] ?? 1) == 1, // Convert integer to boolean
    );
  }

  // Create a copy of Customer with updated fields
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? location,
    String? company,
    String? notes,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalSpent,
    int? totalInvoices,
    double? balance,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      location: location ?? this.location,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalSpent: totalSpent ?? this.totalSpent,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get full address as formatted string
  String get fullAddress {
    List<String> addressParts = [];
    if (address.isNotEmpty) addressParts.add(address);
    if (city.isNotEmpty) addressParts.add(city);
    if (location.isNotEmpty) addressParts.add(location);
    return addressParts.join(', ');
  }

  // Get display name (company or name)
  String get displayName {
    return company.isNotEmpty ? company : name;
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, email: $email, phone: $phone, company: $company}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Empty customer factory
  static Customer empty() {
    return Customer(
      id: 0,
      name: '',
      email: '',
      phone: '',
      address: '',
      city: '',
      location: '',
      company: '',
      notes: '',
      profileImage: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalSpent: 0.0,
      totalInvoices: 0,
      balance: 0.0,
      isActive: true,
    );
  }
}