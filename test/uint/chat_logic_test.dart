
import 'package:flutter_test/flutter_test.dart';


class MockChatLogic {
  final String personName;
  final String personUid;
  final String myUid;
  
  MockChatLogic({
    required this.personName,
    required this.personUid,
    required this.myUid,
  });
  
  String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    int hour = date.hour;
    int minute = date.minute;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "$hour:${minute.toString().padLeft(2, '0')} $ampm";
  }
}

void main() {
  test('Mock formatTime works', () {
    final chat = MockChatLogic(
      personName: 'Test',
      personUid: '1',
      myUid: '2',
    );
    
    final time = DateTime(2024, 1, 1, 9, 30).millisecondsSinceEpoch;
    expect(chat.formatTime(time), '9:30 AM');
  });
  
  test('Mock constructor works', () {
    final chat = MockChatLogic(
      personName: 'John',
      personUid: '123',
      myUid: '456',
    );
    
    expect(chat.personName, 'John');
    expect(chat.personUid, '123');
    expect(chat.myUid, '456');
  });
}
