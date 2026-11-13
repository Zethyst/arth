// A discount code as the API answers it (POST /v1/coupons/check).
// Mirrors api/src/services/coupons.ts.
//
// A coupon carries no price. It names a cheaper offer that Google Play or the
// App Store already holds, and the stores quote the price themselves — which
// is why the reader sees a real store price, in their own currency, and the
// purchase is a normal store purchase.

import 'package:arth/data/account.dart';

enum CouponPeriod { monthly, yearly }

class CouponOffer {
  const CouponOffer({
    required this.code,
    required this.tier,
    required this.androidOfferTag,
    required this.iosDiscountId,
    this.period,
    this.label = '',
    this.labelHi = '',
  });

  factory CouponOffer.fromJson(Map<String, dynamic> j) => CouponOffer(
        code: j['code'] as String,
        tier: switch (j['tier']) {
          'super' => Tier.superTier,
          _ => Tier.pro,
        },
        period: switch (j['period']) {
          'monthly' => CouponPeriod.monthly,
          'yearly' => CouponPeriod.yearly,
          _ => null,
        },
        androidOfferTag: (j['androidOfferTag'] as String?) ?? '',
        iosDiscountId: (j['iosDiscountId'] as String?) ?? '',
        label: (j['label'] as String?) ?? '',
        labelHi: (j['labelHi'] as String?) ?? '',
      );

  final String code;
  final Tier tier;

  /// Null when the code applies to both the monthly and the yearly plan.
  final CouponPeriod? period;

  /// A tag on a Google Play base-plan offer.
  final String androidOfferTag;

  /// An App Store promotional-offer identifier.
  final String iosDiscountId;

  final String label;
  final String labelHi;

  String labelFor({required bool hindi}) {
    final hi = labelHi.trim();
    final en = label.trim();
    if (hindi && hi.isNotEmpty) return hi;
    return en.isNotEmpty ? en : hi;
  }

  /// Whether this code applies to a given plan on the Plans screen.
  bool appliesTo({required Tier tier, required bool yearly}) {
    if (tier != this.tier) return false;
    return switch (period) {
      null => true,
      CouponPeriod.yearly => yearly,
      CouponPeriod.monthly => !yearly,
    };
  }
}
