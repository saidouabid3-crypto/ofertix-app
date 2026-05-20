class AppCategory {
  final String id;
  final String name;
  final String icon;
  final String image;

  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
  });
}

class AppCategories {
  static const List<AppCategory> all = [
    AppCategory(
      id: 'technology',
      name: 'Technology',
      icon: '💻',
      image: 'assets/categories/technology.png',
    ),

    AppCategory(
      id: 'fashion',
      name: 'Fashion',
      icon: '👕',
      image: 'assets/categories/fashion.png',
    ),

    AppCategory(
      id: 'home',
      name: 'Home',
      icon: '🏠',
      image: 'assets/categories/home.png',
    ),

    AppCategory(
      id: 'beauty',
      name: 'Beauty',
      icon: '💄',
      image: 'assets/categories/beauty.png',
    ),

    AppCategory(
      id: 'sports',
      name: 'Sports',
      icon: '⚽',
      image: 'assets/categories/sports.png',
    ),

    AppCategory(
      id: 'gaming',
      name: 'Gaming',
      icon: '🎮',
      image: 'assets/categories/gaming.png',
    ),

    AppCategory(
      id: 'supermarket',
      name: 'Supermarket',
      icon: '🛒',
      image: 'assets/categories/supermarket.png',
    ),

    AppCategory(
      id: 'travel',
      name: 'Travel',
      icon: '✈️',
      image: 'assets/categories/travel.png',
    ),

    AppCategory(
      id: 'kids',
      name: 'Kids',
      icon: '🧸',
      image: 'assets/categories/kids.png',
    ),

    AppCategory(
      id: 'automotive',
      name: 'Automotive',
      icon: '🚗',
      image: 'assets/categories/automotive.png',
    ),
  ];

  static AppCategory? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
