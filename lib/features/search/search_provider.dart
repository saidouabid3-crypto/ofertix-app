import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/country_service.dart';

class SearchProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading = false;
  bool isError = false;
  List<Product> results = [];
  List<String> suggestions = [];
  Map<String, dynamic>? detectedIntent;
  List<String> recentSearches = [];

  // ── Filters ────────────────────────────────────────────────────────────────
  String? selectedCategory;
  int? minDiscount;
  bool trustedOnly = false;
  String sortMode = 'smart';

  // ── Internal ───────────────────────────────────────────────────────────────
  Timer? _debounce;
  String _lastQuery = '';
  static const _recentKey = 'ofertix_recent_searches';
  static const _maxRecent = 10;

  SearchProvider() {
    _loadRecentSearches();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  void setInitialResults(List<Product> products) {
    results = List<Product>.from(products);
  }

  // ── Debounced typing ───────────────────────────────────────────────────────

  void onQueryChanged(String query, {String? countryCode}) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      results = [];
      suggestions = [];
      detectedIntent = null;
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(query, countryCode: countryCode);
    });
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> search(String query, {String? countryCode}) async {
    final q = query.trim();
    if (q.isEmpty) return;

    isLoading = true;
    isError = false;
    _lastQuery = q;
    notifyListeners();

    try {
      final country = countryCode ?? await CountryService.instance.getCurrentCountry();

      final body = <String, dynamic>{
        'query': q,
        'country': country,
        'limit': 40,
        if (selectedCategory != null) 'category': selectedCategory,
        if (minDiscount != null) 'minDiscount': minDiscount,
        'trustedOnly': trustedOnly,
        'sort': sortMode,
      };

      final response = await ApiService.instance.post(
        '/api/products/search',
        body: body,
      );

      if (response is Map) {
        final data = Map<String, dynamic>.from(response);

        // Products
        final rawProducts = data['products'];
        if (rawProducts is List) {
          results = rawProducts
              .map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                return Product.fromMap(m, m['id']?.toString() ?? '');
              })
              .toList();
        } else {
          results = [];
        }

        // Suggestions
        final rawSugg = data['suggestions'];
        suggestions = rawSugg is List
            ? List<String>.from(rawSugg.whereType<String>())
            : [];

        // Intent
        detectedIntent = data['detectedIntent'] is Map
            ? Map<String, dynamic>.from(data['detectedIntent'] as Map)
            : null;

        await _saveRecentSearch(q);
      } else {
        results = [];
        suggestions = [];
        detectedIntent = null;
      }
    } catch (_) {
      isError = true;
      results = [];
      suggestions = [];
      detectedIntent = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Re-run with current filters ───────────────────────────────────────────

  Future<void> reapplyFilters({String? countryCode}) async {
    if (_lastQuery.isEmpty) return;
    await search(_lastQuery, countryCode: countryCode);
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  void setCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
    if (_lastQuery.isNotEmpty) reapplyFilters();
  }

  void setMinDiscount(int? value) {
    minDiscount = value;
    notifyListeners();
    if (_lastQuery.isNotEmpty) reapplyFilters();
  }

  void setTrustedOnly(bool value) {
    trustedOnly = value;
    notifyListeners();
    if (_lastQuery.isNotEmpty) reapplyFilters();
  }

  void setSortMode(String mode) {
    sortMode = mode;
    notifyListeners();
    if (_lastQuery.isNotEmpty) reapplyFilters();
  }

  void clearFilters() {
    selectedCategory = null;
    minDiscount = null;
    trustedOnly = false;
    sortMode = 'smart';
    notifyListeners();
    if (_lastQuery.isNotEmpty) reapplyFilters();
  }

  // ── Recent searches ────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recentKey);
      if (json != null) {
        final decoded = jsonDecode(json);
        if (decoded is List) {
          recentSearches = List<String>.from(decoded.whereType<String>());
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String q) async {
    if (q.isEmpty) return;
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    if (recentSearches.length > _maxRecent) {
      recentSearches = recentSearches.take(_maxRecent).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentKey, jsonEncode(recentSearches));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
    notifyListeners();
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  void clear() {
    _debounce?.cancel();
    results = [];
    suggestions = [];
    detectedIntent = null;
    isError = false;
    _lastQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
