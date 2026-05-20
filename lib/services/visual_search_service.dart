class VisualSearchService {
  Future<List<dynamic>> searchImage(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [];
  }

  Future<List<dynamic>> searchByImage(String imagePath) async {
    return searchImage(imagePath);
  }
}
