import 'package:flutter/material.dart';

enum Condition { newCondition, good, used }
enum RentalType { hourly, daily, weekly, monthly, yearly }
enum ProductStatus { available, rented }

class EquipmentItem {
  final String id;

  // OWNER DATA
  final String ownerUid;
  final String ownerName;
  final String? ownerPhoto;

  final String category;              // MAIN category
  final String subCategory;           // SUB category
  final String title;

  final double pricePerHour;
  final double? pricePerDay;
  final double? pricePerWeek;
  final double? pricePerMonth;
  final double? pricePerYear;

  final Condition condition;
  final RentalType rentalType;
  final IconData icon;
  final String description;

  bool isFavorite;
  double rating;
  int reviews;
  int likes;
  int rentedCount;

  final int releaseYear;
  final List<String> specs;
  final List<String> images;

  final double? latitude;
  final double? longitude;

  List<String> userReviews;
  double userRating;

  ProductStatus status;

  EquipmentItem({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    this.ownerPhoto,
    required this.category,        // NOW a single category
    required this.subCategory,     // NEW
    required this.title,
    required this.pricePerHour,
    required this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
    this.pricePerYear,
    required this.condition,
    required this.rentalType,
    required this.icon,
    this.description = '',
    this.isFavorite = false,
    this.rating = 0.0,
    this.reviews = 0,
    this.likes = 0,
    this.rentedCount = 0,
    this.releaseYear = 2024,
    this.specs = const [],
    this.images = const [],
    this.latitude,
    this.longitude,
    this.userReviews = const [],
    this.userRating = 0.0,
    this.status = ProductStatus.available,
  });

  double getPriceForRentalType(RentalType type) {
    switch (type) {
      case RentalType.hourly:
        return pricePerHour;
      case RentalType.daily:
        return pricePerDay ?? pricePerHour * 24;
      case RentalType.weekly:
        return pricePerWeek ?? (pricePerDay ?? pricePerHour * 24) * 7;
      case RentalType.monthly:
        return pricePerMonth ?? (pricePerDay ?? pricePerHour * 24) * 30;
      case RentalType.yearly:
        return pricePerYear ?? pricePerHour * 24 * 365;
    }
  }
}


final List<EquipmentItem> allEquipments = [
  EquipmentItem(
    id: "1",
    ownerUid: "iJ6LJ6sQPBblHXq29xGMNXQqt0h2",
    ownerName: "",
    category: "Computers & Mobiles",
    subCategory: "Laptops",
    title: "Laptop",
    pricePerHour: 2.0,
    pricePerDay: 25.0,
    pricePerWeek: 150.0,
    pricePerMonth: 500.0,
    pricePerYear: 4000.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.laptop,
    description: "Good laptop for work and study.",
    specs: ["i5 11th Gen", "8GB RAM", "256GB SSD", "14 inch"],
    rating: 4.7,
    reviews: 124,
    likes: 88,
    rentedCount: 52,
    latitude: 31.963158,
    longitude: 35.930359,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "2",
    ownerUid: "GNsiZcg9HyZxtbADqyC8PeDnu8k2",
    ownerName: "",
    category: "Sports",
    subCategory: "Camping",
    title: "4-Person Camping Tent",
    pricePerHour: 1.0,
    pricePerDay: 12.0,
    pricePerWeek: 70.0,
    pricePerMonth: 230.0,
    pricePerYear: 1800.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.park,
    description: "Waterproof tent for family camping trips.",
    specs: ["4-Person Capacity", "Waterproof", "UV Protection"],
    rating: 4.5,
    reviews: 89,
    likes: 67,
    rentedCount: 45,
    latitude: 31.992,
    longitude: 35.957,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "3",
    ownerUid: "iJ6LJ6sQPBblHXq29xGMNXQqt0h2",
    ownerName: "",
    category: "Tools & Devices",
    subCategory: "Maintenance Tools",
    title: "Bosch Power Drill",
    pricePerHour: 1.0,
    pricePerDay: 12.0,
    pricePerWeek: 75.0,
    pricePerMonth: 250.0,
    pricePerYear: 2000.0,
    condition: Condition.used,
    rentalType: RentalType.weekly,
    icon: Icons.build,
    description: "Durable electric drill.",
    specs: ["Cordless", "18V Battery"],
    rating: 4.4,
    reviews: 33,
    likes: 26,
    rentedCount: 18,
    latitude: 31.99,
    longitude: 35.89,
    status: ProductStatus.rented,
  ),

  EquipmentItem(
    id: "4",
    ownerUid: "GNsiZcg9HyZxtbADqyC8PeDnu8k2",
    ownerName: "",
    category: "Home & Garden",
    subCategory: "Garden Equipment",
    title: "Electric Lawn Mower",
    pricePerHour: 2.0,
    pricePerDay: 24.0,
    pricePerWeek: 145.0,
    pricePerMonth: 480.0,
    pricePerYear: 3800.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.grass,
    description: "Electric mower for gardens.",
    rating: 4.5,
    reviews: 92,
    likes: 78,
    rentedCount: 56,
    latitude: 31.985,
    longitude: 35.950,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "5",
    ownerUid: "iJ6LJ6sQPBblHXq29xGMNXQqt0h2",
    ownerName: "",
    category: "Fashion & Clothing",
    subCategory: "Women",
    title: "Designer Evening Gown",
    pricePerHour: 3.0,
    pricePerDay: 35.0,
    pricePerWeek: 200.0,
    pricePerMonth: 700.0,
    pricePerYear: 5500.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.checkroom,
    description: "Elegant designer dress.",
    specs: ["Size M", "Silk"],
    rating: 4.9,
    reviews: 145,
    likes: 300,
    rentedCount: 89,
    latitude: 32.005,
    longitude: 35.973,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "10",
    ownerUid: "GNsiZcg9HyZxtbADqyC8PeDnu8k2",
    ownerName: "",
    category: "Electronics",
    subCategory: "Audio & Video",
    title: "Sony WH-1000XM4",
    pricePerHour: 1.5,
    pricePerDay: 18.0,
    pricePerWeek: 110.0,
    pricePerMonth: 400.0,
    pricePerYear: 3000.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.headphones,
    description: "Noise cancelling headphones.",
    specs: ["30h Battery"],
    rating: 4.8,
    reviews: 52,
    likes: 98,
    rentedCount: 40,
    latitude: 32.0,
    longitude: 35.92,
    status: ProductStatus.available,
  ),
];
 final DUMMY_EQUIPMENT = allEquipments;