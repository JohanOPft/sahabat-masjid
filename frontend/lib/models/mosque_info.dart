class MosqueInfo {
  final String name;
  final String address;
  final String? description;
  final String bankName;
  final String bankAccount;
  final String bankHolder;
  final String? qrisImage;
  final String? donationInfo;
  final String? whatsappContact;

  MosqueInfo({
    required this.name,
    required this.address,
    this.description,
    required this.bankName,
    required this.bankAccount,
    required this.bankHolder,
    this.qrisImage,
    this.donationInfo,
    this.whatsappContact,
  });

  factory MosqueInfo.fromJson(Map<String, dynamic> json) {
    return MosqueInfo(
      name: json['name'] as String? ?? 'Masjid Al-Ikhlas',
      address: json['address'] as String? ?? 'Semarang',
      description: json['description'] as String?,
      bankName: json['bank_name'] as String? ?? 'Bank Syariah Indonesia (BSI)',
      bankAccount: json['bank_account'] as String? ?? '7123456789',
      bankHolder: json['bank_holder'] as String? ?? 'Masjid Al-Ikhlas',
      qrisImage: json['qris_image'] as String?,
      donationInfo: json['donation_info'] as String?,
      whatsappContact: json['whatsapp_contact'] as String? ?? '6281234567890',
    );
  }
}
