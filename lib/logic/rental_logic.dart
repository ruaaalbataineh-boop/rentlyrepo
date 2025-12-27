import 'package:flutter/material.dart';

enum RentalType { hourly, daily, weekly, monthly, yearly }

class RentalCalculator {
  static double calculateTotalPrice({
    required RentalType rentalType,
    required double basePrice,
    required DateTime? startDate,
    required DateTime? endDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (rentalType == RentalType.hourly) {
      if (startDate == null || startTime == null || endTime == null) return 0.0;
      return _calculateHourlyPrice(basePrice, startDate, startTime, endTime);
    } else {
      if (startDate == null || endDate == null) return 0.0;
      if (endDate.isBefore(startDate)) return 0.0;
      
      switch (rentalType) {
        case RentalType.daily:
          return _calculateDailyPrice(basePrice, startDate, endDate);
        case RentalType.weekly:
          return _calculateWeeklyPrice(basePrice, startDate, endDate);
        case RentalType.monthly:
          return _calculateMonthlyPrice(basePrice, startDate, endDate);
        case RentalType.yearly:
          return _calculateYearlyPrice(basePrice, startDate, endDate);
        default:
          return 0.0;
      }
    }
  }

  static double _calculateHourlyPrice(
      double basePrice, DateTime startDate, TimeOfDay startTime, TimeOfDay endTime) {
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      endTime.hour,
      endTime.minute,
    );
    
    if (endDateTime.isBefore(startDateTime)) return 0.0;

    final duration = endDateTime.difference(startDateTime);
    final totalMinutes = duration.inMinutes;
    
    if (totalMinutes <= 0) return 0.0;
    
   
    if (totalMinutes <= 60) return basePrice;
    
  
    final totalHours = (totalMinutes / 60).ceilToDouble();
    return basePrice * totalHours;
  }

  static double _calculateDailyPrice(double basePrice, DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
   
    if (days == 0) return basePrice;
    
    return basePrice * (days + 1);
  }

  static double _calculateWeeklyPrice(double basePrice, DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    final weeks = (days / 7).ceilToDouble();
    return basePrice * weeks;
  }

  static double _calculateMonthlyPrice(double basePrice, DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    final months = (days / 30).ceilToDouble();
    return basePrice * months;
  }

  static double _calculateYearlyPrice(double basePrice, DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    final years = (days / 365).ceilToDouble();
    return basePrice * years;
  }

  static double calculateTotalHours({
    required RentalType rentalType,
    required DateTime? startDate,
    required DateTime? endDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (startDate == null) return 0.0;

    if (rentalType == RentalType.hourly) {
      if (startTime == null || endTime == null) return 0.0;
      
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute,
      );
      final endDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        endTime.hour,
        endTime.minute,
      );
      
      if (endDateTime.isBefore(startDateTime)) return 0.0;
      
      final duration = endDateTime.difference(startDateTime);
      return duration.inHours.toDouble();
    } else {
      if (endDate == null) return 0.0;
      if (endDate.isBefore(startDate)) return 0.0;
     
      final days = endDate.difference(startDate).inDays;
    
      if (days == 0) return 24.0;
      
      return (days + 1) * 24.0;
    }
  }

  static bool isValidRentalTypeForDuration({
  required RentalType rentalType,
  required DateTime? startDate,
  required DateTime? endDate,
  required TimeOfDay? startTime,
  required TimeOfDay? endTime,
}) {
  if (startDate == null) return false;
  
 
  if (rentalType == RentalType.hourly) {
    if (endDate != null && !_isSameDay(startDate, endDate)) {
      return false; 
    }
    if (startTime == null || endTime == null) return false;
  } else {
    
    if (endDate == null) return false;
    if (endDate.isBefore(startDate)) return false;
  }
  
  final totalHours = calculateTotalHours(
    rentalType: rentalType,
    startDate: startDate,
    endDate: rentalType == RentalType.hourly ? startDate : endDate,
    startTime: startTime,
    endTime: endTime,
  );
  
  if (totalHours <= 0) return false;
  
  switch (rentalType) {
    case RentalType.hourly:
      return totalHours <= 24;
    case RentalType.daily:
      return totalHours <= (24 * 6); 
    case RentalType.weekly:
      return totalHours <= (24 * 30);
    case RentalType.monthly:
      return totalHours <= (24 * 365); 
    case RentalType.yearly:
      return true;
  }
}


static bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}
}
