import 'package:flutter/material.dart';

enum Condition { newCondition, good, used }
enum RentalType { daily, weekly, monthly }

class EquipmentItem {
  final String id;
  final List<String> categories; 
  final String title;
  final double pricePerDay;
  final Condition condition;
  final RentalType rentalType;
  final IconData icon;
  final String description;
  bool isFavorite;

  final double rating;      
  final int reviews;          
  final int likes;            
  final int rentedCount;      
  final int releaseYear;      
  final List<String> specs;   
  final List<String> images;  

 
  final double? latitude;
  final double? longitude;

  EquipmentItem({
    required this.id,
    required this.categories,
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
  });
}
final laptop = EquipmentItem(
  id: "1",
  categories: ["Electronics"],
  title: "Laptop",
  pricePerDay: 15.0,
  condition: Condition.good,
  rentalType: RentalType.daily,
  icon: Icons.camera_alt,
  description: "A good laptop for work and study",
  latitude: 31.963158,   
  longitude: 35.930359,  
);
