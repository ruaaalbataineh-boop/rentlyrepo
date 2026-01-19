import 'package:flutter/material.dart';
import 'package:p2/services/auth_service.dart';
import 'package:p2/views/Equipment_Detail_Page.dart';
import 'package:provider/provider.dart';

import '../controllers/favourite_controller.dart';
import '../models/Item.dart';

class FavouritePage extends StatelessWidget {
  static const routeName = '/favorites';

  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {

    final fav = context.watch<FavouriteController>();
    final auth = context.read<AuthService>();
    if (auth.currentUid != null) {
      fav.bindIfNeeded(auth.currentUid!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favourites"),
      ),
      body: fav.isLoading && fav.favourites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(fav),
    );
  }

  Widget _buildBody(FavouriteController fav) {
    if (!fav.hasFavourites) {
      return Center(
        child: Text(
          fav.emptyMessage,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    final items = fav.items;

    if (items.isEmpty) {
      return Center(
        child: Text(
          fav.noItemsMessage,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(context, fav, item);
      },
    );
  }

  Widget _buildItemCard(
      BuildContext context,
      FavouriteController fav,
      Map<String, dynamic> itemData,
      ) {
    final itemId = fav.getItemId(itemData);
    final itemName = fav.getItemName(itemData);
    final imageUrl = fav.getItemImage(itemData);
    final priceText = fav.getItemPriceText(itemData);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          EquipmentDetailPage.routeName,
          arguments: Item.fromMap(itemData),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 80),
              )
                  : const SizedBox(
                height: 140,
                child: Center(child: Icon(Icons.image, size: 80)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Price
                  Text(
                    priceText,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 60),
        ),
      );
    }
    return const Icon(Icons.image, size: 60);
  }

  Widget _buildItemName(String name) {
    return Text(
      name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildItemPrice(String priceText) {
    return Text(
      priceText,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildRemoveText() {
    return const Text(
      "Tap to remove",
      style: TextStyle(color: Colors.red),
    );
  }
}
