import '../localization/language_config.dart';

/// Single, framework-agnostic source of truth for the locale/country/currency
/// that the network layer attaches to every outgoing request.
///
/// WHY THIS EXISTS:
/// The HTTP transport ([ApiService]) is a pure singleton with no access to a
/// Flutter [BuildContext]. Reading `context.locale` from inside it would couple
/// the network layer to the widget tree and make it untestable. Instead, the
/// app pushes the active locale into this holder whenever it changes (see
/// `OfertixApp` / `main.dart`), and the transport reads it synchronously.
///
/// This keeps the contract one-directional and safe:
///   easy_localization / LocaleProvider  ->  LocaleResolver  ->  ApiService
///
/// The backend (Phase 2) reads the headers produced here from request middleware
/// so that every AI verdict, insight, and assistant reply is generated in the
/// user's active UI language.
class LocaleResolver {
  LocaleResolver._();

  /// Global instance used by the transport. Replaceable in tests.
  static final LocaleResolver instance = LocaleResolver._();

  String _languageCode = LanguageConfig.defaultLanguageCode;
  String? _countryCode;
  String? _currencyCode;

  /// Active, normalized 2-letter UI language (never empty).
  String get languageCode => _languageCode;

  /// Active ISO country code (uppercase) if known, e.g. `ES`. May be null.
  String? get countryCode => _countryCode;

  /// Active ISO 4217 currency code (uppercase) if known, e.g. `EUR`. May be null.
  String? get currencyCode => _currencyCode;

  /// `true` when the active language is written right-to-left.
  bool get isRtl => LanguageConfig.isRtl(_languageCode);

  /// Updates the active locale context. Any argument left null is preserved.
  ///
  /// Call this from the app whenever the user changes language, country, or
  /// currency so that subsequent requests are tagged correctly.
  void update({String? languageCode, String? countryCode, String? currencyCode}) {
    if (languageCode != null) {
      _languageCode = LanguageConfig.normalize(languageCode);
    }

    if (countryCode != null) {
      final clean = countryCode.trim().toUpperCase();
      _countryCode = clean.isEmpty ? null : clean;
    }

    if (currencyCode != null) {
      final clean = currencyCode.trim().toUpperCase();
      _currencyCode = clean.isEmpty ? null : clean;
    }
  }

  /// Resets the resolver to defaults. Primarily for tests.
  void reset() {
    _languageCode = LanguageConfig.defaultLanguageCode;
    _countryCode = null;
    _currencyCode = null;
  }

  /// The locale-related headers attached to every request.
  ///
  /// - `Accept-Language`: standard HTTP header; lets generic middleware and
  ///   third parties negotiate language without app-specific knowledge.
  /// - `X-App-Locale` / `X-Ofertix-Language`: unambiguous app-selected UI language (not a preference
  ///   list), which the backend treats as authoritative for AI output language.
  /// - `X-App-Country` / `X-App-Currency`: optional shopping context that the
  ///   AI engine uses for landed-cost, customs, and currency reasoning.
  Map<String, String> get headers {
    final result = <String, String>{
      'Accept-Language': _languageCode,
      'X-App-Locale': _languageCode,
      'X-Ofertix-Language': _languageCode,
    };

    final country = _countryCode;
    if (country != null && country.isNotEmpty) {
      result['X-App-Country'] = country;
    }

    final currency = _currencyCode;
    if (currency != null && currency.isNotEmpty) {
      result['X-App-Currency'] = currency;
    }

    return result;
  }
}
