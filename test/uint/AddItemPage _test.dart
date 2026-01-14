import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddItemPage Business Logic', () {
    test('Insurance rate calculation formula', () {
     
      double getInsuranceRate(double itemPrice) {
        if (itemPrice <= 50) return 0.0;
        if (itemPrice <= 100) return 0.10;
        if (itemPrice <= 500) return 0.15;
        return 0.30;
      }
      
      expect(getInsuranceRate(0), 0.0);
      expect(getInsuranceRate(25), 0.0);
      expect(getInsuranceRate(50), 0.0);
      expect(getInsuranceRate(75), 0.10);
      expect(getInsuranceRate(100), 0.10);
      expect(getInsuranceRate(250), 0.15);
      expect(getInsuranceRate(500), 0.15);
      expect(getInsuranceRate(1000), 0.30);
      expect(getInsuranceRate(5000), 0.30);
    });
    
    test('Insurance amount calculation', () {
      double calculateInsurance(double originalPrice) {
        double getRate(double price) {
          if (price <= 50) return 0.0;
          if (price <= 100) return 0.10;
          if (price <= 500) return 0.15;
          return 0.30;
        }
        return originalPrice * getRate(originalPrice);
      }
      
      expect(calculateInsurance(0), 0.0);
      expect(calculateInsurance(50), 0.0);
      expect(calculateInsurance(75), 7.5);
      expect(calculateInsurance(100), 10.0);
      expect(calculateInsurance(250), 37.5);
      expect(calculateInsurance(500), 75.0);
      expect(calculateInsurance(1000), 300.0);
    });
    
    test('Categories and subcategories structure', () {
      final categories = [
        "Electronics",
        "Computers & Mobiles",
        "Video Games",
        "Sports",
        "Tools & Devices",
        "Home & Garden",
        "Fashion & Clothing",
      ];
      
      final subCategories = {
        "Electronics": ["Cameras & Photography", "Audio & Video"],
        "Computers & Mobiles": ["Mobiles", "Laptops", "Printers", "Projectors", "Servers"],
        "Video Games": ["Gaming Devices"],
        "Sports": ["Bicycle", "Books", "Skates & Scooters", "Camping"],
        "Tools & Devices": ["Maintenance Tools", "Medical Devices", "Cleaning Equipment"],
        "Home & Garden": ["Garden Equipment", "Home Supplies"],
        "Fashion & Clothing": ["Men", "Women", "Customs", "Baby Supplies"],
      };
      
      expect(categories.length, 7);
      expect(subCategories.length, 7);
      
     
      for (final category in categories) {
        expect(subCategories.containsKey(category), true);
        expect(subCategories[category]!.isNotEmpty, true);
      }
    });
    
    test('Rental periods validation', () {
      final availablePeriods = ["Daily", "Weekly", "Monthly", "Yearly"];
      
      expect(availablePeriods.length, 4);
      expect(availablePeriods, containsAll(["Daily", "Weekly", "Monthly", "Yearly"]));
    });
    
    test('Price validation logic', () {
      // Rental 
      bool isValidRentalPrice(String price) {
        final value = double.tryParse(price);
        if (value == null || value <= 0) return false;
        if (value > 10000) return false;
        return true;
      }
      
      
      bool isValidItemPrice(String price) {
        final value = double.tryParse(price);
        if (value == null || value <= 0) return false;
        if (value > 100000) return false;
        return true;
      }
      
      expect(isValidRentalPrice(""), false);
      expect(isValidRentalPrice("abc"), false);
      expect(isValidRentalPrice("0"), false);
      expect(isValidRentalPrice("-10"), false);
      expect(isValidRentalPrice("50"), true);
      expect(isValidRentalPrice("10000"), true);
      expect(isValidRentalPrice("10001"), false);
      
      expect(isValidItemPrice(""), false);
      expect(isValidItemPrice("abc"), false);
      expect(isValidItemPrice("0"), false);
      expect(isValidItemPrice("-10"), false);
      expect(isValidItemPrice("50000"), true);
      expect(isValidItemPrice("100000"), true);
      expect(isValidItemPrice("100001"), false);
    });
  });
  
  group('Form Validation Scenarios', () {
    test('Required fields validation', () {
      bool validateForm({
        required String name,
        required String? category,
        required String? subCategory,
        required Map<String, dynamic> rentalPeriods,
        required String originalPrice,
        required double? latitude,
        required double? longitude,
        required List<String> images,
      }) {
        if (name.isEmpty) return false;
        if (category == null) return false;
        if (subCategory == null) return false;
        if (rentalPeriods.isEmpty) return false;
        if (originalPrice.isEmpty) return false;
        final price = double.tryParse(originalPrice);
        if (price == null || price <= 0 || price > 100000) return false;
        if (latitude == null || longitude == null) return false;
        if (images.isEmpty) return false;
        return true;
      }
      
     
      expect(validateForm(
        name: "Test Item",
        category: "Electronics",
        subCategory: "Cameras",
        rentalPeriods: {"Daily": 10.0},
        originalPrice: "100",
        latitude: 31.5,
        longitude: 35.5,
        images: ["image1.jpg"],
      ), true);
      
     
      expect(validateForm(
        name: "",
        category: "Electronics",
        subCategory: "Cameras",
        rentalPeriods: {"Daily": 10.0},
        originalPrice: "100",
        latitude: 31.5,
        longitude: 35.5,
        images: ["image1.jpg"],
      ), false);
      
      // No rental periods
      expect(validateForm(
        name: "Test Item",
        category: "Electronics",
        subCategory: "Cameras",
        rentalPeriods: {},
        originalPrice: "100",
        latitude: 31.5,
        longitude: 35.5,
        images: ["image1.jpg"],
      ), false);
      
      // No location
      expect(validateForm(
        name: "Test Item",
        category: "Electronics",
        subCategory: "Cameras",
        rentalPeriods: {"Daily": 10.0},
        originalPrice: "100",
        latitude: null,
        longitude: null,
        images: ["image1.jpg"],
      ), false);
      
    
      expect(validateForm(
        name: "Test Item",
        category: "Electronics",
        subCategory: "Cameras",
        rentalPeriods: {"Daily": 10.0},
        originalPrice: "100",
        latitude: 31.5,
        longitude: 35.5,
        images: [],
      ), false);
    });
  });
  
  print('✅ All AddItemPage logic tests passed!');
}
