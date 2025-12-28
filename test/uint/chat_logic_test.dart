import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:p2/fake_uid.dart';
import 'package:p2/logic/chat_logic.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockDatabaseReference mockDbRef;
  late ChatLogic chatLogic;

  setUp(() {
    mockDbRef = MockDatabaseReference();
    LoginUID.uid = "currentUser123";

    chatLogic = ChatLogic(
      personName: "Test User",
      personUid: "testUid123",
      dbRef: mockDbRef, 
    );
  });

 test('ChatLogic constructor initializes chatId correctly', () {
  LoginUID.uid = "currentUser123";
  final chatLogic1 = ChatLogic(
    personName: "Test User",
    personUid: "testUid123",
    dbRef: mockDbRef,
  );
  expect(chatLogic1.chatId, "testUid123-currentUser123");

  LoginUID.uid = "zzz";
  final chatLogic2 = ChatLogic(
    personName: "Test",
    personUid: "bbb",
    dbRef: mockDbRef,
  );
  expect(chatLogic2.chatId, "zzz-bbb");
});
;


  test('canEditOrDelete returns false for non-sender messages', () {
    final msg = {"sender": "otherUser", "timestamp": DateTime.now().millisecondsSinceEpoch - 5000};
    expect(chatLogic.canEditOrDelete(msg), false);
  });

  test('canEditOrDelete returns true for sender messages within 10 minutes', () {
    final msg = {"sender": "currentUser123", "timestamp": DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000};
    expect(chatLogic.canEditOrDelete(msg), true);
  });

  test('canEditOrDelete returns false for sender messages after 10 minutes', () {
    final msg = {"sender": "currentUser123", "timestamp": DateTime.now().millisecondsSinceEpoch - 11 * 60 * 1000};
    expect(chatLogic.canEditOrDelete(msg), false);
  });

  test('formatTime formats correctly', () {
    final timestamp = DateTime(2024, 1, 1, 14, 30).millisecondsSinceEpoch;
    expect(chatLogic.formatTime(timestamp), "2:30 PM");

    final timestamp2 = DateTime(2024, 1, 1, 9, 5).millisecondsSinceEpoch;
    expect(chatLogic.formatTime(timestamp2), "9:05 AM");
  });

  test('messageDateLabel returns correct labels', () {
    final now = DateTime.now();
    final todayTimestamp = now.millisecondsSinceEpoch;
    final yesterdayTimestamp = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final oldTimestamp = DateTime(2023, 1, 1).millisecondsSinceEpoch;

    expect(chatLogic.messageDateLabel(todayTimestamp), "Today");
    expect(chatLogic.messageDateLabel(yesterdayTimestamp), "Yesterday");
    expect(chatLogic.messageDateLabel(oldTimestamp), "2023/1/1");
  });

  test('setReplyMessage and clearReplyMessage work correctly', () {
    final testMsg = {"text": "Test message", "sender": "user1"};

    chatLogic.setReplyMessage(testMsg);
    expect(chatLogic.replyMessage, testMsg);

    chatLogic.clearReplyMessage();
    expect(chatLogic.replyMessage, isNull);
  });

  test('setSelectedMessageKey works correctly', () {
    chatLogic.setSelectedMessageKey("testKey123");
    expect(chatLogic.selectedMessageKey, "testKey123");

    chatLogic.setSelectedMessageKey(null);
    expect(chatLogic.selectedMessageKey, isNull);
  });
}
