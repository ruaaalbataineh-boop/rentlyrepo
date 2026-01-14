import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:p2/Equipment_Detail_Page.dart';
import 'package:p2/models/Item.dart';
import 'package:p2/logic/product_logic.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/input_validator.dart';
import 'package:p2/security/route_guard.dart';
import 'package:p2/security/secure_storage.dart';
import 'package:p2/security/api_security.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  static const routeName = '/product-list';

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String searchQuery = '';
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAuthenticated = false;
  String? _userToken;
  late String _categoryTitle;
  late String _subCategoryTitle;
  bool _argsLoaded = false; 

  @override
  void initState() {
    super.initState();
    
  }

  @override
void didChangeDependencies() {
  super.didChangeDependencies();

  if (_argsLoaded) return;

  _extractArguments();
  _initializeSecurity();
  _argsLoaded = true;
}

  void _extractArguments() {
    try {
      debugPrint(' PRODUCT LIST ARGS: ${ModalRoute.of(context)?.settings.arguments}');//

      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! Map<String, dynamic>) {
        throw Exception('Invalid arguments type');
      }

      if (!args.containsKey("category") || !args.containsKey("subCategory")) {
        throw Exception('Missing required parameters');
      }

      final category = args["category"]?.toString() ?? '';
      final subCategory = args["subCategory"]?.toString() ?? '';

      if (category.isEmpty || subCategory.isEmpty) {
        throw Exception('Empty category or subcategory');
      }

      
      if (!InputValidator.hasNoMaliciousCode(category) ||
          !InputValidator.hasNoMaliciousCode(subCategory)) {
        throw Exception('Invalid characters in parameters');
      }

      
      if (category.length > 50 || subCategory.length > 50) {
        throw Exception('Parameters too long');
      }

      setState(() {
        _categoryTitle = category;
        _subCategoryTitle = subCategory;
      });
    } catch (error) {
      ErrorHandler.logError('Extract Arguments', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
        _categoryTitle = 'Unknown';
        _subCategoryTitle = 'Unknown';
      });
    }
  }

  Future<void> _initializeSecurity() async {
    try {
    
      _isAuthenticated = RouteGuard.isAuthenticated();
      
      
      _userToken = await SecureStorage.getToken();
      
      
      await _logPageAccess();
      
      setState(() => _isLoading = false);
    } catch (error) {
      ErrorHandler.logError('Initialize Security', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _logPageAccess() async {
    try {
      await ApiSecurity.securePost(
        endpoint: 'logs/page_access',
        data: {
          'page': 'product_list',
          'timestamp': DateTime.now().toIso8601String(),
          'user_authenticated': _isAuthenticated,
        },
        token: _userToken,
        requiresAuth: false,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Page Access', 'Failed to log access');
    }
  }

  Future<void> _logSearchActivity(String query) async {
    try {
      final safeCategory = InputValidator.sanitizeInput(_categoryTitle);
      final safeSubCategory = InputValidator.sanitizeInput(_subCategoryTitle);
      
      await ApiSecurity.securePost(
        endpoint: 'logs/search',
        data: {
          'query': query,
          'timestamp': DateTime.now().toIso8601String(),
          'category': safeCategory,
          'subcategory': safeSubCategory,
        },
        token: _userToken,
        requiresAuth: false,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Search Activity', 'Failed to log search');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen(_errorMessage);
    }

  
    final safeCategory = _sanitizeCategory(_categoryTitle);
    final safeSubCategory = _sanitizeCategory(_subCategoryTitle);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      ProductLogic.formatCategoryTitle(safeCategory, safeSubCategory),
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
                onChanged: (value) {
                  final safeValue = InputValidator.sanitizeInput(value);
                  setState(() => searchQuery = safeValue);
                  
        
                  _logSearchActivity(safeValue);
                },
              ),
            ),

          
            Expanded(
              child: _buildSecureProductsStream(safeCategory, safeSubCategory, searchQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading products securely...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeCategory(String input) {
    final sanitized = InputValidator.sanitizeInput(input);
    if (sanitized.isEmpty) {
      return 'Unknown';
    }
    
    // تقييد الطول
    const maxLength = 30;
    return sanitized.length > maxLength 
        ? sanitized.substring(0, maxLength) 
        : sanitized;
  }

  Widget _buildSecureProductsStream(String category, String subCategory, String searchQuery) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("items")
          .where("category", isEqualTo: category)
          .where("subCategory", isEqualTo: subCategory)
          .where("status", isEqualTo: "approved")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final safeError = ErrorHandler.getSafeError(snapshot.error);
          ErrorHandler.logError('Secure Products Stream', snapshot.error);
          return _buildErrorScreen(safeError);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        
        
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: ProductLogic.secureFilterProducts(docs, searchQuery),
          builder: (context, filterSnapshot) {
            if (filterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filterSnapshot.hasError) {
              final safeError = ErrorHandler.getSafeError(filterSnapshot.error);
              return _buildErrorScreen(safeError);
            }

            final filtered = filterSnapshot.data ?? [];
            
            if (!ProductLogic.hasProducts(filtered)) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No products found!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final maxProducts = 100;
            final displayDocs = filtered.length > maxProducts 
                ? filtered.sublist(0, maxProducts) 
                : filtered;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemCount: displayDocs.length,
              itemBuilder: (context, index) {
                try {
                  final doc = displayDocs[index];
                  final itemId = doc.id;

                  
                  final data = doc.data() as Map<String, dynamic>;
                  if (!ProductLogic.validateItemData(data)) {
                    ErrorHandler.logSecurity('Product Display', 
                        'Unsafe product skipped: $itemId');
                    return Container();
                  }

                  return SecureProductTile(
                    itemData: data,
                    itemId: itemId,
                    userToken: _userToken,
                  );
                } catch (error) {
                  ErrorHandler.logError('Build Secure Product Tile', error);
                  return Container();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A005D),
                ),
                child: const Text('Go Back', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecureProductTile extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String itemId;
  final String? userToken;

  const SecureProductTile({
    super.key,
    required this.itemData,
    required this.itemId,
    this.userToken,
  });

  @override
  Widget build(BuildContext context) {
    try {
      
      if (!_validateProductSecurity()) {
        return _buildSecurityWarningTile();
      }

      final safeName = InputValidator.sanitizeInput(itemData["name"]?.toString() ?? "No Title");
      final safeDescription = InputValidator.sanitizeInput(itemData["description"]?.toString() ?? "");
      
      final images = List<String>.from(itemData["images"] ?? []);
      final rental = Map<String, dynamic>.from(itemData["rentalPeriods"] ?? {});

      return GestureDetector(
        onTap: () => _secureNavigateToDetail(context),
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
                  child: _buildSecureProductImage(images),
                ),
              ),

             
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      safeDescription,
                      maxLines: 2,
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
                        final safePriceText = InputValidator.sanitizeInput(priceText);
                        return Text(
                          safePriceText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    } catch (error) {
      ErrorHandler.logError('Build Secure Product Tile UI', error);
      return _buildErrorTile();
    }
  }

  bool _validateProductSecurity() {
    try {
    
      if (itemId.isEmpty) return false;
      
      
      if (!ProductLogic.validateItemData(itemData)) return false;
      
      
      final images = List<String>.from(itemData["images"] ?? []);
      for (var image in images) {
        if (!_isSecureImageUrl(image)) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildSecureProductImage(List<String> images) {
    try {
      if (images.isNotEmpty) {
        final imageUrl = images.first;
        
        
        if (_isSecureImageUrl(imageUrl)) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              ErrorHandler.logError('Load Secure Product Image', error);
              return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
            },
          );
        }
      }
      return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
    } catch (e) {
      ErrorHandler.logError('Build Secure Product Image', e);
      return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
    }
  }

  bool _isSecureImageUrl(String url) {
    try {
      if (url.isEmpty) return false;
      
      final uri = Uri.tryParse(url);
      if (uri == null) return false;
      
      
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      
    
      if (uri.host.isEmpty) return false;
      
      
      if (!InputValidator.hasNoMaliciousCode(url)) return false;
      
      
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final path = uri.path.toLowerCase();
      if (!imageExtensions.any((ext) => path.endsWith(ext))) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _secureNavigateToDetail(BuildContext context) async {
    try {
      
      final item = ProductLogic.secureConvertToItem(itemId, itemData);
    
      if (itemData['status'] != 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product is not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }


      
      
      
      if (_isValidItem(item)) {
        await _logProductView();
        
        Navigator.pushNamed(
          context,
          EquipmentDetailPage.routeName,
          arguments: item,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product information is invalid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ErrorHandler.logError('Secure Navigate to Detail', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getSafeError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidItem(Item item) {
    return item.name.isNotEmpty &&
           item.category.isNotEmpty &&
           item.subCategory.isNotEmpty &&
           itemId.isNotEmpty &&
           item.status == "approved";
  }

  Widget _buildErrorTile() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            'Invalid Product',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityWarningTile() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, color: Colors.orange, size: 40),
          const SizedBox(height: 8),
          Text(
            'Security Check Failed',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _logProductView() async {
    try {
      await ApiSecurity.securePost(
        endpoint: 'logs/product_view',
        data: {
          'itemId': itemId,
          'timestamp': DateTime.now().toIso8601String(),
          'view_type': 'tile_click',
        },
        token: userToken,
        requiresAuth: false,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Product View', 'Failed to log view');
    }
  }
}

class SecureProductCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String itemId;
  final String? userToken;

  const SecureProductCard({
    super.key,
    required this.itemData,
    required this.itemId,
    this.userToken,
  });

  @override
  Widget build(BuildContext context) {
    try {
      if (!ProductLogic.validateItemData(itemData)) {
        return _buildSecurityWarningCard();
      }

      final safeName = InputValidator.sanitizeInput(itemData["name"]?.toString() ?? "No Title");
      final safeDescription = InputValidator.sanitizeInput(itemData["description"]?.toString() ?? "");
      
      final images = List<String>.from(itemData["images"] ?? []);
      final rental = Map<String, dynamic>.from(itemData["rentalPeriods"] ?? {});

      final priceText = ProductLogic.getPriceText(rental);
      final safePriceText = InputValidator.sanitizeInput(priceText);

      return GestureDetector(
        onTap: () => _secureNavigateToDetail(context),
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
                    image: _buildSecureProductCardImage(images),
                  ),
                  child: images.isEmpty || !_isSecureImageUrl(images.first)
                      ? const Icon(Icons.image_not_supported, color: Colors.grey)
                      : null,
                ),

                const SizedBox(width: 12),

            
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        safeDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        safePriceText,
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
    } catch (error) {
      ErrorHandler.logError('Build Secure Product Card', error);
      return _buildErrorCard();
    }
  }

  DecorationImage? _buildSecureProductCardImage(List<String> images) {
    try {
      if (images.isNotEmpty) {
        final imageUrl = images.first;
        if (_isSecureImageUrl(imageUrl)) {
          return DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          );
        }
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('Build Secure Product Card Image', e);
      return null;
    }
  }

  bool _isSecureImageUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri != null && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty &&
             InputValidator.hasNoMaliciousCode(url);
    } catch (e) {
      return false;
    }
  }

  Future<void> _secureNavigateToDetail(BuildContext context) async {
    try {

     /* final isSafe = await ProductLogic.checkProductSafety(itemId);
      
      if (!isSafe) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product security check failed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }*/
     




      final item = ProductLogic.secureConvertToItem(itemId, itemData);
      // add omar 
         if (itemData['status'] != 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product is not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_isValidItem(item)) {
        await _logProductView();
        
        Navigator.pushNamed(
          context,
          EquipmentDetailPage.routeName,
          arguments: item,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product information is invalid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ErrorHandler.logError('Secure Navigate to Detail from Card', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getSafeError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidItem(Item item) {
    return item.name.isNotEmpty &&
           item.category.isNotEmpty &&
           item.subCategory.isNotEmpty &&
           itemId.isNotEmpty;
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading product',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityWarningCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Product security check failed',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logProductView() async {
    try {
      await ApiSecurity.securePost(
        endpoint: 'logs/product_view',
        data: {
          'itemId': itemId,
          'timestamp': DateTime.now().toIso8601String(),
          'view_type': 'card_click',
        },
        token: userToken,
        requiresAuth: false,
      );
    } catch (e) {
      ErrorHandler.logInfo('Log Product View', 'Failed to log view');
    }
  }
}
