String normalizeChatId(String uid1, String uid2) {
  final a = uid1.trim();
  final b = uid2.trim();
  if (a.isEmpty || b.isEmpty) return '$a-$b';
  return (a.compareTo(b) <= 0) ? '$a-$b' : '$b-$a';
}
