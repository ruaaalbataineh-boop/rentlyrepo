
import 'package:flutter/material.dart';
import 'package:p2/logic/favourite_logic.dart';

class FavouritePage extends StatefulWidget {
  static const routeName = '/favorites';

  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final FavouriteLogic _logic = FavouriteLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favourite"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_logic.hasFavourites) {
      return Center(
        child: Text(
          _logic.emptyMessage,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logic.getFavouriteItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              _logic.noItemsMessage,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        final items = snapshot.data!;

        if (items.isEmpty) {
          return Center(
            child: Text(
              _logic.noItemsMessage,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 3 / 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> itemData) {
    final itemId = _logic.getItemId(itemData);
    final itemName = _logic.getItemName(itemData);
    final imageUrl = _logic.getItemImage(itemData);
    final priceText = _logic.getItemPriceText(itemData);

    return GestureDetector(
      onTap: () {
        setState(() {
          _logic.removeFavourite(itemId);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildItemImage(imageUrl),
            const SizedBox(height: 10),
            _buildItemName(itemName),
            const SizedBox(height: 5),
            _buildItemPrice(priceText),
            const SizedBox(height: 10),
            _buildRemoveText(),
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
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 60);
          },
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
