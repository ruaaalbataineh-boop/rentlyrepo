import 'package:flutter/material.dart';

enum Condition { newCondition, good, used }
enum RentalType { daily, weekly, monthly }

class EquipmentItem {
  final String id;
  final List<String> categories;
  final String type;
  final String title;
  final double pricePerDay;
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

  EquipmentItem({
    required this.id,
    required this.categories,
    required this.type, 
    required this.title,
    required this.pricePerDay,
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
  });
}


final List<EquipmentItem> allEquipments = [
  
  EquipmentItem(
    id: "1",
    categories: ["Electronics", "Computers & Technology"],
    type: "Laptop",
    title: "Laptop",
    pricePerDay: 15.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
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
  ),

 
  EquipmentItem(
    id: "2",
    categories: ["Electronics", "Photography"],
    type: "Camera",
    title: "Camera Canon 250D",
    pricePerDay: 20.0,
    condition: Condition.newCondition,
    rentalType: RentalType.daily,
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
  ),

  
  EquipmentItem(
    id: "3",
    categories: ["Electronics", "Audio"],
    type: "Headphones",
    title: "Sony WH-1000XM4",
    pricePerDay: 10.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
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
  ),

  EquipmentItem(
    id: "4",
    categories: ["Tools & Equipment", "Garden & Home"],
    type: "Power Drill",
    title: "Bosch Power Drill",
    pricePerDay: 8.0,
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
  ),

  EquipmentItem(
    id: "5",
    categories: ["Sports & Camping", "Fitness"],
    type: "Dumbbells",
    title: "Adjustable Dumbbells Set",
    pricePerDay: 6.0,
    condition: Condition.good,
    rentalType: RentalType.daily,
    icon: Icons.fitness_center,
    description: "Adjustable dumbbells 5–30kg.",
    specs: ["30KG Max", "Rubber Grip"],
    images: ["assets/images/dumbbells.jpg"],
    rating: 4.5,
    reviews: 41,
    likes: 30,
    rentedCount: 21,
    latitude: 31.97,
    longitude: 35.93,
  ),
];

