import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:p2/logic/profile_logic_page.dart';

class FakeFile implements File {
  final String fakePath;
  final int fakeLength;

  FakeFile(this.fakePath, this.fakeLength);

  @override
  Future<int> length() async => fakeLength;

  @override
  String get path => fakePath;

  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProfileLogic logic;

  setUp(() {
    logic = ProfileLogic(
      fullName: 'John Doe',
      email: 'john@example.com',
      phone: '1234567890',
      location: 'Amman',
      bank: 'ABC Bank',
      testMode: true, 
    );
  });

  group('ProfileLogic Unit Tests', () {
    test('hasImage returns false initially', () {
      expect(logic.hasImage(), false);
    });

    test('isProfileChanged detects name change', () {
      final changed = logic.isProfileChanged(name: 'New Name');
      expect(changed, true);
    });

    test('validateImageSafety accepts small valid image', () async {
      final file = FakeFile('photo.jpg', 1024); // 1KB
      final safe = await logic.validateImageSafety(file);
      expect(safe, true);
    });

    test('validateImageSafety rejects large image', () async {
      final file = FakeFile('photo.png', 10 * 1024 * 1024); // 10MB
      final safe = await logic.validateImageSafety(file);
      expect(safe, false);
    });

    test('updateProfile returns true for valid input in testMode', () async {
      final file = FakeFile('photo.jpg', 1024);
      final success = await logic.updateProfile(
        name: 'John New',
        email: 'johnnew@example.com',
        phone: '1234567890',
        image: file,
      );
      expect(success, true);
      expect(logic.fullName, 'John New');
      expect(logic.email, 'johnnew@example.com');
      expect(logic.phone, '1234567890');
      expect(logic.profileImage, file);
    });
  });
}
