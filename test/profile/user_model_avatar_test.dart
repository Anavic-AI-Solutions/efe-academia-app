import 'package:efe_mobile/features/auth/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses avatar_url and falls back to avatar', () {
    final withUrl = UserModel.fromJson({
      'data': {
        'id': 1,
        'name': 'Ada',
        'email': 'ada@example.com',
        'avatar_url': 'https://cdn/a.png',
      },
    });
    expect(withUrl.avatarUrl, 'https://cdn/a.png');

    final withAvatar = UserModel.fromJson({
      'data': {
        'id': 1,
        'name': 'Ada',
        'email': 'ada@example.com',
        'avatar': 'https://cdn/b.png',
      },
    });
    expect(withAvatar.avatarUrl, 'https://cdn/b.png');

    final both = UserModel.fromJson({
      'data': {
        'id': 1,
        'name': 'Ada',
        'email': 'ada@example.com',
        'avatar_url': 'https://cdn/a.png',
        'avatar': 'https://cdn/b.png',
      },
    });
    expect(both.avatarUrl, 'https://cdn/a.png');

    final none = UserModel.fromJson({
      'data': {
        'id': 1,
        'name': 'Ada',
        'email': 'ada@example.com',
      },
    });
    expect(none.avatarUrl, isNull);
  });
}
