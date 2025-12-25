import 'Item.dart';

/// Maps Firestore rentalPeriod keys to RentalType enum
enum RentalType {
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
}

RentalType rentalTypeFromKey(String key) {
  switch (key.toLowerCase()) {
    case "hourly":
      return RentalType.hourly;
    case "daily":
      return RentalType.daily;
    case "weekly":
      return RentalType.weekly;
    case "monthly":
      return RentalType.monthly;
    case "yearly":
      return RentalType.yearly;
    default:
      throw Exception("Unknown rental period: $key");
  }
}

/// Extension to easily fetch price for selected rental type
extension ItemPriceExtension on Item {
  double getPrice(RentalType type) {
    String key = type.toString().split('.').last; // hourly, daily, weekly...
    if (rentalPeriods.containsKey(key)) {
      return (rentalPeriods[key] as num).toDouble();
    }
    return 0.0;
  }
}
