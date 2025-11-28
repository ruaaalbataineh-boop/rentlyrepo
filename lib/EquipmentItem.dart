import 'package:flutter/material.dart';

enum Condition { newCondition, good, used }
enum RentalType { hourly, weekly, monthly, yearly }
enum ProductStatus { available, rented }

class EquipmentItem {
  final String id;
  final List<String> categories;
  final String type;
  final String title;
  final double pricePerHour;
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
    required this.categories,
    required this.type, 
    required this.title,
    required this.pricePerHour,
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
      case RentalType.weekly:
        return pricePerWeek ?? pricePerHour * 24 * 7;
      case RentalType.monthly:
        return pricePerMonth ?? pricePerHour * 24 * 30;
      case RentalType.yearly:
        return pricePerYear ?? pricePerHour * 24 * 365;
    }
  }
}

final List<EquipmentItem> allEquipments = [
  EquipmentItem(
    id: "1",
    categories: ["Electronics", "Computers & Technology"],
    type: "Laptop",
    title: "Laptop",
    pricePerHour: 2.0,
    pricePerWeek: 25.0,
    pricePerMonth: 80.0,
    pricePerYear: 800.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.laptop,
    description: "Good laptop for work and study.",
    specs: ["i5 11th Gen", "8GB RAM", "256GB SSD", "14 inch"],
    images: ["assets/images/laptop1.jpg", "assets/images/laptop2.jpg"],
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
    categories: ["Electronics", "Photography"],
    type: "Camera",
    title: "Camera Canon 250D",
    pricePerHour: 3.0,
    pricePerWeek: 40.0,
    pricePerMonth: 120.0,
    pricePerYear: 1200.0,
    condition: Condition.newCondition,
    rentalType: RentalType.hourly,
    icon: Icons.camera_alt,
    description: "4K camera perfect for photography and video shooting.",
    specs: ["4K Video", "24MP", "Touch Screen"],
    images: ["assets/images/camera1.jpg", "assets/images/camera2.jpg"],
    rating: 4.9,
    reviews: 76,
    likes: 140,
    rentedCount: 63,
    latitude: 31.95,
    longitude: 35.91,
    status: ProductStatus.rented,
  ),
  EquipmentItem(
    id: "3",
    categories: ["Electronics", "Audio"],
    type: "Headphones",
    title: "Sony WH-1000XM4",
    pricePerHour: 1.5,
    pricePerWeek: 20.0,
    pricePerMonth: 60.0,
    pricePerYear: 600.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.headphones,
    description: "Noise cancelling headphones with high sound quality.",
    specs: ["Noise Canceling", "Bluetooth 5.0", "30h Battery"],
    images: ["assets/images/headphones1.jpg"],
    rating: 4.8,
    reviews: 52,
    likes: 98,
    rentedCount: 40,
    latitude: 32.0,
    longitude: 35.92,
    status: ProductStatus.available,
  ),
  EquipmentItem(
    id: "4",
    categories: ["Tools & Equipment", "Garden & Home"],
    type: "Power Drill",
    title: "Bosch Power Drill",
    pricePerHour: 1.0,
    pricePerWeek: 12.0,
    pricePerMonth: 35.0,
    pricePerYear: 350.0,
    condition: Condition.used,
    rentalType: RentalType.weekly,
    icon: Icons.build,
    description: "Durable electric drill for home and workshop use.",
    specs: ["Cordless", "18V Battery", "2 Speed Modes"],
    images: ["assets/images/drill.jpg"],
    rating: 4.4,
    reviews: 33,
    likes: 26,
    rentedCount: 18,
    latitude: 31.99,
    longitude: 35.89,
    status: ProductStatus.rented,
  ),
  EquipmentItem(
    id: "5",
    categories: ["Sports & Camping", "Fitness"],
    type: "Dumbbells",
    title: "Adjustable Dumbbells Set",
    pricePerHour: 0.8,
    pricePerWeek: 10.0,
    pricePerMonth: 25.0,
    pricePerYear: 250.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.fitness_center,
    description: "Adjustable dumbbells 5–30kg.",
    specs: ["30KG Max", "Rubber Grip"],
    images: ["assets/images/dumbells.jpg"],
    rating: 4.5,
    reviews: 41,
    likes: 30,
    rentedCount: 21,
    latitude: 31.97,
    longitude: 35.93,
    status: ProductStatus.available,
  ),
];

final DUMMY_EQUIPMENT = allEquipments;
