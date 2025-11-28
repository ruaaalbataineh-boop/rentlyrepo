import 'package:flutter/material.dart';
import 'Fake data.dart';
import 'EquipmentItem.dart' hide DUMMY_EQUIPMENT;
import 'Equipment_Detail_Page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  static const routeName = '/product-list';

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    if (routeArgs == null) return const SizedBox();

    final type = routeArgs['type']!;
    final categoryTitle = routeArgs['title']!;

    final allItems = DUMMY_EQUIPMENT
        .where((eq) => eq.type == type)
        .toList();

    final displayedItems = allItems
        .where((item) =>
            item.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      categoryTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: displayedItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found!',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedItems.length,
                        itemBuilder: (ctx, index) {
                          final item = displayedItems[index];
                          return ProductCard(item: item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final EquipmentItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        EquipmentDetailPage.routeName,
        arguments: item,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A005D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 30,
                  color: const Color(0xFF8A005D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, 
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            _navigateToEditPage(context, item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, 
                              color: Colors.grey, size: 20),
                          onPressed: () {
                            _showDeleteDialog(context, item);
                          },
                        ),
                      ],
                    ),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "JOD ${item.getPriceForRentalType(item.rentalType).toStringAsFixed(2)}/${_getRentalTypeText(item.rentalType)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A005D),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Produced: ${item.releaseYear}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusText(item.status),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getRentalTypeText(item.rentalType).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.rented:
        return Colors.orange;
    }
  }

  String _getStatusText(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return 'AVAILABLE';
      case ProductStatus.rented:
        return 'RENTED';
    }
  }

  String _getRentalTypeText(RentalType type) {
    switch (type) {
      case RentalType.hourly:
        return 'hour';
      case RentalType.weekly:
        return 'week';
      case RentalType.monthly:
        return 'month';
      case RentalType.yearly:
        return 'year';
    }
  }

  void _navigateToEditPage(BuildContext context, EquipmentItem item) {
    Navigator.pushNamed(
      context,
      '/add-item',
      arguments: item,
    );
  }

  void _showDeleteDialog(BuildContext context, EquipmentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.title}" deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
