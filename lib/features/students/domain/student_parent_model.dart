import '../../requests/domain/request_model.dart';

class StudentParentModel {
  final String id;
  final String fullname;
  final String email;
  final String phone;
  final String address;
  final String identityNumber;
  final String status;
  final List<RequestMedia> media;

  const StudentParentModel({
    required this.id,
    this.fullname = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.identityNumber = '',
    this.status = '',
    this.media = const [],
  });

  factory StudentParentModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        json['data']?['attributes'] as Map<String, dynamic>? ??
        json;
    return StudentParentModel(
      id: json['data']?['id']?.toString() ??
          json['id']?.toString() ??
          attrs['id']?.toString() ??
          '',
      fullname: attrs['fullname']?.toString() ?? '',
      email: attrs['email']?.toString() ?? '',
      phone: attrs['phone']?.toString() ?? '',
      address: attrs['address']?.toString() ?? '',
      identityNumber:
          (attrs['identity_number'] ?? attrs['identityNumber'])?.toString() ??
              '',
      status: attrs['status']?.toString() ?? '',
      media: _parseMedia(attrs['media']),
    );
  }

  static List<RequestMedia> _parseMedia(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(RequestMedia.fromJson)
        .toList();
  }
}
