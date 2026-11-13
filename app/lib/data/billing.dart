// Buying Pro and Super in the app stores, through RevenueCat.
//
// The reader is identified to RevenueCat by their Firebase uid (logIn on
// sign-in), so a purchase follows the account, and the API's webhook
// (api/src/routes/billing.ts) turns it into their plan. After buying or
// restoring, the app asks the API to apply it straight away (/billing/sync).
//
// RevenueCat's "current" offering carries four packages, by identifier:
// pro_monthly, pro_yearly, super_monthly, super_yearly. Prices, trials and
// intro prices all come from the stores, never from here.
//
//   --dart-define=REVENUECAT_ANDROID_KEY=goog_…  (public SDK keys)
//   --dart-define=REVENUECAT_IOS_KEY=appl_…

import 'dart:io';

import 'package:arth/data/account.dart';
import 'package:arth/data/coupon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

/// One way to pay for a plan, as the Plans screen shows it.
class PlanOffer {
  const PlanOffer({
    required this.tier,
    required this.yearly,
    required this.price,
    required this.priceString,
    this.currencyCode = 'INR',
    this.freeTrialDays,
    this.introPriceString,
    this.introMonths,
    this.package,
    this.coupon,
    this.subscriptionOption,
    this.discount,
    this.fullPriceString,
  });

  final Tier tier;
  final bool yearly;

  /// In the store's currency, for "about ₹50 a month" and savings.
  final double price;
  final String priceString;
  final String currencyCode;

  /// A free trial the reader can start (7 days).
  final int? freeTrialDays;

  /// A cheaper start: [introPriceString] a month for [introMonths] months.
  final String? introPriceString;
  final int? introMonths;

  /// The RevenueCat package to buy; null in tests.
  final Package? package;

  /// The discount code that produced this offer, when it is a coupon price.
  final CouponOffer? coupon;

  /// Google Play: the base-plan offer the coupon unlocked, bought instead of
  /// the package's default option.
  final SubscriptionOption? subscriptionOption;

  /// App Store: the promotional offer the coupon unlocked. It has to be
  /// signed (by RevenueCat) just before buying, so only the identifier is
  /// kept here.
  final StoreProductDiscount? discount;

  /// What the plan costs without the coupon, for striking through.
  final String? fullPriceString;

  bool get discounted => coupon != null;
}

/// The Play base-plan offer a coupon's tag names, or null if this product has
/// none. A store that has never heard of the tag is the normal case before
/// the offer is published, so it is not an error.
SubscriptionOption? androidOptionFor(StoreProduct product, String offerTag) {
  if (offerTag.isEmpty) return null;
  for (final o in product.subscriptionOptions ?? const <SubscriptionOption>[]) {
    if (!o.isBasePlan && o.tags.contains(offerTag)) return o;
  }
  return null;
}

/// The App Store promotional offer a coupon's identifier names, or null.
StoreProductDiscount? iosDiscountFor(StoreProduct product, String discountId) {
  if (discountId.isEmpty) return null;
  for (final d in product.discounts ?? const <StoreProductDiscount>[]) {
    if (d.identifier == discountId) return d;
  }
  return null;
}

/// [base] re-priced by [coupon], or null when this store holds no such offer
/// or the coupon is not for this plan. The price always comes from the store.
PlanOffer? couponOfferFrom(
  PlanOffer base,
  CouponOffer coupon, {
  required StoreProduct product,
  required bool android,
}) {
  if (!coupon.appliesTo(tier: base.tier, yearly: base.yearly)) return null;
  if (android) {
    final option = androidOptionFor(product, coupon.androidOfferTag);
    // What the reader is charged first: the offer's intro phase when it has
    // one, otherwise its recurring price.
    final phase = option?.introPhase ?? option?.fullPricePhase;
    if (option == null || phase == null) return null;
    return PlanOffer(
      tier: base.tier,
      yearly: base.yearly,
      price: phase.price.amountMicros / 1000000,
      priceString: phase.price.formatted,
      currencyCode: phase.price.currencyCode,
      package: base.package,
      coupon: coupon,
      subscriptionOption: option,
      fullPriceString: base.priceString,
    );
  }
  final discount = iosDiscountFor(product, coupon.iosDiscountId);
  if (discount == null) return null;
  return PlanOffer(
    tier: base.tier,
    yearly: base.yearly,
    price: discount.price,
    priceString: discount.priceString,
    currencyCode: base.currencyCode,
    package: base.package,
    coupon: coupon,
    discount: discount,
    fullPriceString: base.priceString,
  );
}

/// Days in a period like "P1W" / "P7D" / "P1M".
int? _days(String? iso) {
  final m = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso ?? '');
  if (m == null) return null;
  final n = int.parse(m.group(1)!);
  return switch (m.group(2)) { 'D' => n, 'W' => n * 7, 'M' => n * 30, _ => n * 365 };
}

/// What a store product offers: its price, and a trial or intro price if
/// this reader can have one. Google Play puts the best offer the reader is
/// eligible for on [StoreProduct.defaultOption]; the App Store on
/// [StoreProduct.introductoryPrice].
PlanOffer planOfferFrom(StoreProduct p, {required Tier tier, required bool yearly, Package? package}) {
  int? trialDays;
  String? introPrice;
  int? introMonths;
  final option = p.defaultOption;
  if (option != null) {
    final free = option.freePhase;
    if (free != null) trialDays = _days(free.billingPeriod?.iso8601);
    final intro = option.introPhase;
    if (intro != null) {
      introPrice = intro.price.formatted;
      final cycles = intro.billingCycleCount ?? 1;
      final months = (_days(intro.billingPeriod?.iso8601) ?? 30) ~/ 30;
      introMonths = cycles * (months == 0 ? 1 : months);
    }
  } else {
    final intro = p.introductoryPrice;
    if (intro != null) {
      if (intro.price == 0) {
        trialDays = _days(intro.period) ?? intro.periodNumberOfUnits * 7;
      } else {
        introPrice = intro.priceString;
        introMonths = intro.cycles * (intro.periodUnit == PeriodUnit.year ? 12 : 1);
      }
    }
  }
  return PlanOffer(
    tier: tier,
    yearly: yearly,
    price: p.price,
    priceString: p.priceString,
    currencyCode: p.currencyCode,
    freeTrialDays: trialDays,
    introPriceString: introPrice,
    introMonths: introMonths,
    package: package,
  );
}

enum BuyOutcome { bought, cancelled, failed }

class Billing {
  /// Whether this build can sell plans (it was given a RevenueCat key).
  /// RevenueCat's `test_…` keys only work in debug builds: in a release build
  /// the SDK closes the app, so there they count as no key at all.
  bool get available => _usable(Platform.isAndroid ? _androidKey : (Platform.isIOS ? _iosKey : ''));

  static bool _usable(String key) => key.isNotEmpty && (kDebugMode || !key.startsWith('test_'));

  bool _ready = false;

  /// The account to buy for; kept until the SDK is ready, since sign-in
  /// can be restored before [init] finishes.
  String? _uid;

  Future<void> init() async {
    if (!available) return;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.info : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(Platform.isIOS ? _iosKey : _androidKey));
      _ready = true;
      if (_uid != null) await identify(_uid);
    } on PlatformException catch (e) {
      debugPrint('billing init failed: $e');
    }
  }

  /// Follows sign-in: purchases belong to the account, not the phone.
  Future<void> identify(String? uid) async {
    _uid = uid;
    if (!_ready) return;
    try {
      if (uid != null) {
        await Purchases.logIn(uid);
      } else if (!await Purchases.isAnonymous) {
        await Purchases.logOut();
      }
    } on PlatformException catch (e) {
      debugPrint('billing identify failed: $e');
    }
  }

  /// The four ways to pay, or null if the store can't be reached.
  Future<List<PlanOffer>?> offers() async {
    if (!_ready) return null;
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        debugPrint('billing offers: no current offering (have: ${offerings.all.keys.join(', ')})');
        return null;
      }
      final out = <PlanOffer>[];
      for (final (id, tier, yearly) in const [
        ('pro_yearly', Tier.pro, true),
        ('pro_monthly', Tier.pro, false),
        ('super_yearly', Tier.superTier, true),
        ('super_monthly', Tier.superTier, false),
      ]) {
        final pkg = current.getPackage(id);
        if (pkg != null) out.add(planOfferFrom(pkg.storeProduct, tier: tier, yearly: yearly, package: pkg));
      }
      if (out.isEmpty) debugPrint('billing offers: "${current.identifier}" has none of the four packages (has: ${current.availablePackages.map((p) => p.identifier).join(', ')})');
      return out.isEmpty ? null : out;
    } on PlatformException catch (e) {
      debugPrint('billing offers failed: $e');
      return null;
    }
  }

  /// [base] re-priced by every coupon offer the stores actually hold.
  /// A code the stores don't know yet yields nothing rather than an error:
  /// the offer may simply not be published.
  List<PlanOffer> couponOffers(List<PlanOffer> base, CouponOffer coupon) {
    final android = Platform.isAndroid;
    final out = <PlanOffer>[];
    for (final o in base) {
      final product = o.package?.storeProduct;
      if (product == null) continue;
      final priced = couponOfferFrom(o, coupon, product: product, android: android);
      if (priced != null) out.add(priced);
    }
    return out;
  }

  /// Buys [offer]. A coupon price is a normal store purchase at a cheaper
  /// offer the store owns: on Google Play that is the base-plan offer the
  /// coupon's tag names, on the App Store a promotional offer RevenueCat
  /// signs just before the purchase.
  Future<BuyOutcome> buy(PlanOffer offer) async {
    final pkg = offer.package;
    if (!_ready || pkg == null) return BuyOutcome.failed;
    try {
      final option = offer.subscriptionOption;
      final discount = offer.discount;
      if (option != null) {
        await Purchases.purchase(PurchaseParams.subscriptionOption(option));
      } else if (discount != null) {
        final promo = await Purchases.getPromotionalOffer(pkg.storeProduct, discount);
        await Purchases.purchase(PurchaseParams.package(pkg, promotionalOffer: promo));
      } else {
        await Purchases.purchase(PurchaseParams.package(pkg));
      }
      return BuyOutcome.bought;
    } on PlatformException catch (e) {
      return PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError ? BuyOutcome.cancelled : BuyOutcome.failed;
    }
  }

  /// A new phone, or a reinstall: bring back what this store account bought.
  Future<bool> restore() async {
    if (!_ready) return false;
    try {
      await Purchases.restorePurchases();
      return true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// The store's own page for changing or cancelling the subscription.
  Future<String?> managementUrl() async {
    if (!_ready) return null;
    try {
      return (await Purchases.getCustomerInfo()).managementURL;
    } on PlatformException catch (_) {
      return null;
    }
  }
}
