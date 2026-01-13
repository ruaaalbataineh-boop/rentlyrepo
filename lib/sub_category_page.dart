import 'package:flutter/material.dart';
import 'package:p2/ProductListPage.dart';
import 'package:p2/logic/sub_category_logic.dart';
import 'package:p2/security/error_handler.dart';
import 'package:p2/security/sub_category_security.dart';

class SubCategoryPage extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  late List<Map<String, dynamic>> _subCategories;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!SubCategorySecurity.isValidCategoryId(widget.categoryId)) {
        throw Exception('Invalid category ID');
      }

      if (!SubCategorySecurity.isValidCategoryTitle(widget.categoryTitle)) {
        throw Exception('Invalid category title');
      }

      
      _hasAccess = await SubCategorySecurity.canAccessCategory(widget.categoryId);
      if (!_hasAccess) {
        throw Exception('Access denied to this category');
      }

      
      final sanitizedData = SubCategorySecurity.sanitizeCategoryData(
        widget.categoryId,
        widget.categoryTitle,
      );

      
      final rawSubCategories = SubCategoryLogic.getSubCategories(sanitizedData['categoryId']!);
      
      
      _subCategories = rawSubCategories.map(
        (subCat) => SubCategorySecurity.sanitizeSubCategoryData(subCat)
      ).toList();

      
      await SubCategorySecurity.logCategoryAccess(
        widget.categoryId,
        widget.categoryTitle,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Initialize SubCategory Page', error);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorHandler.getSafeError(error);
        });
      }
    }
  }

  void _handleSubCategoryTap(Map<String, dynamic> subCategory, String categoryTitle) {
    try {
      final subCategoryTitle = subCategory['title'] as String;
      
    
      if (subCategoryTitle.isEmpty) {
        throw Exception('Invalid sub-category title');
      }

      ErrorHandler.logInfo('SubCategory Tap', 
          'Selected: $subCategoryTitle from $categoryTitle');

      Navigator.pushNamed(
        context,
        ProductListPage.routeName,
        arguments: {
          "subCategory": subCategoryTitle,
          "category": categoryTitle,
        },
      );
    } catch (error) {
      ErrorHandler.logError('Handle SubCategory Tap', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getSafeError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: SideCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 50, bottom: 40),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.categoryTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A005D)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading categories...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializePage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You do not have permission to access this category',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A005D),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesGrid() {
    if (_subCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No sub-categories available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Category: ${widget.categoryTitle}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: _subCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final sub = _subCategories[index];

          return GestureDetector(
            key: ValueKey('sub_${sub["title"]}_$index'),
            onTap: () => _handleSubCategoryTap(sub, widget.categoryTitle),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sub["icon"] as IconData,
                    size: 55,
                    color: const Color(0xFF8A005D),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      sub["title"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : !_hasAccess
                    ? _buildAccessDeniedScreen()
                    : _errorMessage != null
                      ? _buildErrorScreen()
                      : _buildSubCategoriesGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

class SideCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 40.0;
    final path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.arcToPoint(
      Offset(radius, size.height - radius),
      radius: const Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width - radius, size.height - radius);
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: const Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
