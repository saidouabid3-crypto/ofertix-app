import '../../models/product.dart';
import '../../services/affiliate_service.dart';
import '../../services/analytics_service.dart';
import '../../services/price_history_service.dart';

class ProductDetailsRepository {
  Future<void> openAffiliate(Product product) async {
    await AnalyticsService.track(
      event: 'product_click',
      data: {'productId': product.id, 'store': product.store},
    );

    await AffiliateService.open(product.affiliateUrl);
  }

  Future<void> trackPrice(Product product) async {
    await PriceHistoryService.addPrice(
      productId: product.id,
      price: product.newPrice,
    );
  }
}
