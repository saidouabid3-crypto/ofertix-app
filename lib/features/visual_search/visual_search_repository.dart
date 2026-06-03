import '../../services/visual_search_service.dart';

class VisualSearchRepository {
  final VisualSearchService _service = VisualSearchService();

  Future<dynamic> searchImage(String imagePath) {
    return _service.searchImage(imagePath);
  }
}
