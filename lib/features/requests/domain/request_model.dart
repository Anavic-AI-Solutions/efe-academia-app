enum RequestKind {
  student,
  parent;

  static RequestKind fromValue(String? value) {
    return (value ?? '').toLowerCase() == 'parent'
        ? RequestKind.parent
        : RequestKind.student;
  }
}

class RequestMedia {
  final String collectionName;
  final String fileName;
  final String mimeType;
  final String url;

  const RequestMedia({
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.url = '',
  });

  factory RequestMedia.fromJson(Map<String, dynamic> json) {
    return RequestMedia(
      collectionName:
          (json['collection_name'] ?? json['collectionName'])?.toString() ?? '',
      fileName: (json['file_name'] ?? json['fileName'])?.toString() ?? '',
      mimeType: (json['mime_type'] ?? json['mimeType'])?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class RequestChild {
  final String id;
  final String fullname;
  final String identityNumber;
  final String status;
  final String branch;
  final String year;

  const RequestChild({
    required this.id,
    this.fullname = '',
    this.identityNumber = '',
    this.status = '',
    this.branch = '',
    this.year = '',
  });

  factory RequestChild.fromJson(Map<String, dynamic> json) {
    return RequestChild(
      id: json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      identityNumber:
          (json['identity_number'] ?? json['identityNumber'])?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
    );
  }
}

class RequestModel {
  final String id;
  final RequestKind kind;
  final String fullname;
  final String email;
  final String phone;
  final String address;
  final String identityNumber;
  final String branch;
  final String year;
  final String status;
  final int childrenCount;
  final List<RequestChild> children;
  final List<RequestMedia> media;
  final DateTime? createdAt;

  const RequestModel({
    required this.id,
    this.kind = RequestKind.student,
    this.fullname = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.identityNumber = '',
    this.branch = '',
    this.year = '',
    this.status = '',
    this.childrenCount = 0,
    this.children = const [],
    this.media = const [],
    this.createdAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        (data is Map ? data['attributes'] as Map<String, dynamic>? : null) ??
        json;
    final rawId =
        json['id'] ?? (data is Map ? data['id'] : null) ?? attrs['id'];

    return RequestModel(
      id: rawId?.toString() ?? '',
      kind: RequestKind.fromValue(attrs['kind']?.toString()),
      fullname: attrs['fullname']?.toString() ?? '',
      email: attrs['email']?.toString() ?? '',
      phone: attrs['phone']?.toString() ?? '',
      address: attrs['address']?.toString() ?? '',
      identityNumber:
          (attrs['identity_number'] ?? attrs['identityNumber'])?.toString() ??
              '',
      branch: attrs['branch']?.toString() ?? '',
      year: attrs['year']?.toString() ?? '',
      status: attrs['status']?.toString() ?? '',
      childrenCount:
          _parseInt(attrs['children_count'] ?? attrs['childrenCount']),
      children: _parseChildren(attrs['children']),
      media: _parseMedia(attrs['media']),
      createdAt: attrs['created_at'] != null
          ? DateTime.tryParse(attrs['created_at'].toString())
          : attrs['createdAt'] != null
              ? DateTime.tryParse(attrs['createdAt'].toString())
              : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<RequestChild> _parseChildren(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(RequestChild.fromJson)
        .toList();
  }

  static List<RequestMedia> _parseMedia(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(RequestMedia.fromJson)
        .toList();
  }
}
