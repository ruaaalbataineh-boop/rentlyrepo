import 'package:flutter/material.dart';
import 'Fake data.dart';
import 'EquipmentItem.dart';
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
        .where((eq) => eq.title == type)
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
                  const SizedBox(width: 10),
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
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
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
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 60, color: const Color(0xFF8A005D)),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
