/// A media item attached to a parent (for example the DNI photos).
class ParentMedia {
  final String collectionName;
  final String fileName;
  final String mimeType;
  final String url;

  const ParentMedia({
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.url = '',
  });

  factory ParentMedia.fromJson(Map<String, dynamic> json) {
    return ParentMedia(
      collectionName:
          (json['collection_name'] ?? json['collectionName'])?.toString() ?? '',
      fileName: (json['file_name'] ?? json['fileName'])?.toString() ?? '',
      mimeType: (json['mime_type'] ?? json['mimeType'])?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class ParentModel {
  final String id;
  final String fullname;
  final String email;
  final String phone;
  final String address;
  final String identityNumber;
  final String status;
  final String currentStudentId;
  final List<String> studentIds;
  final int studentCount;
  final List<ParentMedia> media;

  const ParentModel({
    required this.id,
    this.fullname = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.identityNumber = '',
    this.status = '',
    this.currentStudentId = '',
    this.studentIds = const [],
    this.studentCount = 0,
    this.media = const [],
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        dataMap?['attributes'] as Map<String, dynamic>? ??
        json;
    final relationships = json['relationships'] as Map<String, dynamic>? ??
        dataMap?['relationships'] as Map<String, dynamic>?;
    final students = relationships?['students']?['data'] as List<dynamic>?;

    return ParentModel(
      id: dataMap?['id']?.toString() ??
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
      currentStudentId: (attrs['current_student_id'] ??
              attrs['currentStudentId'])
          ?.toString() ??
          '',
      studentIds: _parseStudentIds(students),
      studentCount: students?.length ?? 0,
      media: _parseMedia(attrs['media']),
    );
  }

  static List<String> _parseStudentIds(List<dynamic>? students) {
    if (students == null) return const [];
    return students
        .whereType<Map<String, dynamic>>()
        .map((student) => student['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static List<ParentMedia> _parseMedia(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ParentMedia.fromJson)
        .toList();
  }
}
