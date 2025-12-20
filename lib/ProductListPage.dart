
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Equipment_Detail_Page.dart';
import 'Item.dart';
import '../logic/product_logic.dart';

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
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String categoryTitle = args["category"];
    final String subCategoryTitle = args["subCategory"];

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
                      ProductLogic.formatCategoryTitle(categoryTitle, subCategoryTitle),
                      style: const TextStyle(
                        fontSize: 22,
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("items")
                    .where("category", isEqualTo: categoryTitle)
                    .where("subCategory", isEqualTo: subCategoryTitle)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final filtered = ProductLogic.filterProducts(docs, searchQuery);

                  if (!ProductLogic.hasProducts(filtered)) {
                    return const Center(
                      child: Text(
                        'No products found!',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;
                      return ProductTile(
                        itemData: data,
                        itemId: filtered[index].id,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String itemId;

  const ProductTile({
    super.key,
    required this.itemData,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(itemData["images"] ?? []);
    final rental = Map<String, dynamic>.from(itemData["rentalPeriods"] ?? {});

    return GestureDetector(
      onTap: () {
        final item = ProductLogic.convertToItem(itemId, itemData);
        
        Navigator.pushNamed(
          context,
          EquipmentDetailPage.routeName,
          arguments: item,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: images.isNotEmpty
                    ? Image.network(
                        images.first,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported, size: 40),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemData["name"] ?? "No Title",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    itemData["description"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Pricing:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF8A005D),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ProductLogic.formatRentalPeriods(rental).map((priceText) {
                      return Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String itemId;

  const ProductCard({
    super.key,
    required this.itemData,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(itemData["images"] ?? []);
    final rental = Map<String, dynamic>.from(itemData["rentalPeriods"] ?? {});

    final priceText = ProductLogic.getPriceText(rental);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        EquipmentDetailPage.routeName,
        arguments: {
          "itemId": itemId,
          "data": itemData,
        },
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A005D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  image: images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: images.isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData["name"] ?? "No Title",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      itemData["description"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A005D),
                      ),
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
}
