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

  final List<String> categories;
  final String type;
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
    required this.categories,
    required this.type,
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
    ownerUid: "user001",
    ownerName: "Ahmad",
    ownerPhoto: null,
    categories: ["Electronics", "Computers & Technology"],
    type: "Laptop",
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
    images: [],
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
    ownerUid: "user002",
    ownerName: "Omar",
    ownerPhoto: null,
    categories: ["Sports & Camping", "Outdoor"],
    type: "Tent",
    title: "4-Person Camping Tent",
    pricePerHour: 1.0,
    pricePerDay: 12.0,
    pricePerWeek: 70.0,
    pricePerMonth: 230.0,
    pricePerYear: 1800.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.forest,
    description: "Waterproof tent for family camping trips.",
    specs: ["4-Person Capacity", "Waterproof", "UV Protection", "Easy Setup"],
    images: [],
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
    ownerUid: "user003",
    ownerName: "Yousef",
    ownerPhoto: null,
    categories: ["Tools & Equipment", "Garden & Home"],
    type: "Power Drill",
    title: "Bosch Power Drill",
    pricePerHour: 1.0,
    pricePerDay: 12.0,
    pricePerWeek: 75.0,
    pricePerMonth: 250.0,
    pricePerYear: 2000.0,
    condition: Condition.used,
    rentalType: RentalType.weekly,
    icon: Icons.build,
    description: "Durable electric drill for home and workshop use.",
    specs: ["Cordless", "18V Battery", "2 Speed Modes"],
    images: [],
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
    ownerUid: "user004",
    ownerName: "Sara",
    ownerPhoto: null,
    categories: ["Tools & Equipment", "Garden & Home"],
    type: "Lawn Mower",
    title: "Electric Lawn Mower",
    pricePerHour: 2.0,
    pricePerDay: 24.0,
    pricePerWeek: 145.0,
    pricePerMonth: 480.0,
    pricePerYear: 3800.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.grass,
    description: "Lightweight electric lawn mower for small to medium gardens.",
    specs: ["40cm Cutting Width", "Foldable Handle", "Grass Collector", "Adjustable Height"],
    images: [],
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
    ownerUid: "user005",
    ownerName: "Lina",
    ownerPhoto: null,
    categories: ["Clothing & Fashion", "Formal Wear"],
    type: "Evening Dress",
    title: "Designer Evening Gown",
    pricePerHour: 3.0,
    pricePerDay: 35.0,
    pricePerWeek: 200.0,
    pricePerMonth: 700.0,
    pricePerYear: 5500.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.checkroom,
    description: "Elegant designer evening dress for special occasions.",
    specs: ["Size M", "Silk Material", "Dry Clean Only", "Gold Embellishments"],
    images: [],
    rating: 4.9,
    reviews: 145,
    likes: 300,
    rentedCount: 89,
    latitude: 32.005,
    longitude: 35.973,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "6",
    ownerUid: "user006",
    ownerName: "Mohammad",
    ownerPhoto: null,
    categories: ["Electronics", "Computers & Technology"],
    type: "Tablet",
    title: "iPad Pro 12.9-inch",
    pricePerHour: 2.0,
    pricePerDay: 24.0,
    pricePerWeek: 145.0,
    pricePerMonth: 480.0,
    pricePerYear: 3800.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.tablet,
    description: "Professional tablet for design and creative work.",
    specs: ["M1 Chip", "12.9-inch Display", "5G Support", "Apple Pencil Compatible"],
    images: [],
    rating: 4.8,
    reviews: 167,
    likes: 280,
    rentedCount: 89,
    latitude: 31.978,
    longitude: 35.942,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "7",
    ownerUid: "user007",
    ownerName: "Rania",
    ownerPhoto: null,
    categories: ["Sports & Camping", "Fitness"],
    type: "Dumbbells",
    title: "Adjustable Dumbbells Set",
    pricePerHour: 0.8,
    pricePerDay: 9.5,
    pricePerWeek: 60.0,
    pricePerMonth: 200.0,
    pricePerYear: 1500.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.fitness_center,
    description: "Adjustable dumbbells 5–30kg.",
    specs: ["30KG Max", "Rubber Grip"],
    images: [],
    rating: 4.5,
    reviews: 41,
    likes: 30,
    rentedCount: 21,
    latitude: 31.97,
    longitude: 35.93,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "8",
    ownerUid: "user008",
    ownerName: "Hani",
    ownerPhoto: null,
    categories: ["Tools & Equipment", "Power Tools"],
    type: "Circular Saw",
    title: "Cordless Circular Saw",
    pricePerHour: 1.5,
    pricePerDay: 18.0,
    pricePerWeek: 110.0,
    pricePerMonth: 380.0,
    pricePerYear: 3000.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.cut,
    description: "Powerful cordless circular saw for woodworking.",
    specs: ["6.5-inch Blade", "Battery Included", "Laser Guide", "Safety Lock"],
    images: [],
    rating: 4.7,
    reviews: 78,
    likes: 65,
    rentedCount: 41,
    latitude: 31.982,
    longitude: 35.947,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "9",
    ownerUid: "user009",
    ownerName: "Majd",
    ownerPhoto: null,
    categories: ["Clothing & Fashion", "Accessories"],
    type: "Designer Handbag",
    title: "Luxury Handbag",
    pricePerHour: 2.0,
    pricePerDay: 25.0,
    pricePerWeek: 150.0,
    pricePerMonth: 500.0,
    pricePerYear: 4000.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.shopping_bag,
    description: "Designer luxury handbag for events and special occasions.",
    specs: ["Genuine Leather", "Gold Hardware", "Shoulder Strap", "Dust Bag Included"],
    images: [],
    rating: 4.7,
    reviews: 98,
    likes: 180,
    rentedCount: 52,
    latitude: 32.008,
    longitude: 35.975,
    status: ProductStatus.available,
  ),

  EquipmentItem(
    id: "10",
    ownerUid: "user010",
    ownerName: "Fadi",
    ownerPhoto: null,
    categories: ["Electronics", "Audio"],
    type: "Headphones",
    title: "Sony WH-1000XM4",
    pricePerHour: 1.5,
    pricePerDay: 18.0,
    pricePerWeek: 110.0,
    pricePerMonth: 400.0,
    pricePerYear: 3000.0,
    condition: Condition.good,
    rentalType: RentalType.hourly,
    icon: Icons.headphones,
    description: "Noise cancelling headphones with high sound quality.",
    specs: ["Noise Canceling", "Bluetooth 5.0", "30h Battery"],
    images: [],
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
