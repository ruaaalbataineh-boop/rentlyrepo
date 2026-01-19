import '../logic/sub_category_logic.dart';

class SubCategoryController {
  static List<Map<String, dynamic>> getSubCategories(String categoryId) {
    return SubCategoryLogic.getSubCategories(categoryId);
  }
}
