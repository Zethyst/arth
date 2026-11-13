import 'package:arth/data/account.dart';
import 'package:arth/data/billing.dart';
import 'package:arth/data/coupon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

Period _period(PeriodUnit unit, int value, String iso) => Period(unit, value, iso);
Price _inr(double rupees) => Price('₹${rupees.round()}', (rupees * 1e6).round(), 'INR');

SubscriptionOption _option(
  String id,
  String productId, {
  required List<String> tags,
  PricingPhase? full,
  PricingPhase? intro,
}) =>
    SubscriptionOption(id, productId, productId, [?intro, ?full], tags, false, null, false, full, null, intro, null, null);

/// A Play product with a plain base plan plus one tagged discount offer.
StoreProduct _play(String id, double price, {List<SubscriptionOption> options = const []}) => StoreProduct(
      id,
      '',
      id,
      price,
      '₹${price.round()}',
      'INR',
      subscriptionOptions: options,
    );

CouponOffer _coupon({
  Tier tier = Tier.pro,
  CouponPeriod? period = CouponPeriod.yearly,
  String android = 'pro_yearly_40off',
  String ios = 'pro_yearly_40off',
}) =>
    CouponOffer(
      code: 'MAYUR40',
      tier: tier,
      period: period,
      androidOfferTag: android,
      iosDiscountId: ios,
      label: '40% off the first year',
      labelHi: 'पहले साल 40% छूट',
    );

PlanOffer _base(StoreProduct p, {Tier tier = Tier.pro, bool yearly = true}) =>
    planOfferFrom(p, tier: tier, yearly: yearly, package: Package(r'$rc_annual', PackageType.annual, p, const PresentedOfferingContext('current', null, null)));

void main() {
  group('CouponOffer.appliesTo', () {
    test('a yearly Pro code is for the yearly Pro plan only', () {
      final c = _coupon();
      expect(c.appliesTo(tier: Tier.pro, yearly: true), isTrue);
      expect(c.appliesTo(tier: Tier.pro, yearly: false), isFalse);
      expect(c.appliesTo(tier: Tier.superTier, yearly: true), isFalse);
    });

    test('a code with no period is for both', () {
      final c = _coupon(period: null);
      expect(c.appliesTo(tier: Tier.pro, yearly: true), isTrue);
      expect(c.appliesTo(tier: Tier.pro, yearly: false), isTrue);
    });
  });

  group('CouponOffer.labelFor', () {
    test('each language gets its own line, and falls back to the other', () {
      expect(_coupon().labelFor(hindi: true), 'पहले साल 40% छूट');
      expect(_coupon().labelFor(hindi: false), '40% off the first year');
      const onlyHi = CouponOffer(code: 'X', tier: Tier.pro, androidOfferTag: 'a', iosDiscountId: '', labelHi: 'छूट');
      expect(onlyHi.labelFor(hindi: false), 'छूट');
    });
  });

  group('couponOfferFrom on Google Play', () {
    final intro = PricingPhase(_period(PeriodUnit.year, 1, 'P1Y'), RecurrenceMode.finiteRecurring, 1, _inr(599), OfferPaymentMode.discountedRecurringPayment);
    final full = PricingPhase(_period(PeriodUnit.year, 1, 'P1Y'), RecurrenceMode.infiniteRecurring, null, _inr(999), null);
    final product = _play('pro_yearly', 999, options: [
      _option('offer', 'pro_yearly', tags: ['pro_yearly_40off'], full: full, intro: intro),
    ]);

    test("the store's offer price replaces the plain one, which stays struck through", () {
      final o = couponOfferFrom(_base(product), _coupon(), product: product, android: true);
      expect(o, isNotNull);
      expect(o!.priceString, '₹599');
      expect(o.price, 599);
      expect(o.fullPriceString, '₹999');
      expect(o.discounted, isTrue);
      expect(o.subscriptionOption?.id, 'offer');
    });

    test('a tag the store has never heard of yields nothing, not an error', () {
      expect(couponOfferFrom(_base(product), _coupon(android: 'nope'), product: product, android: true), isNull);
    });

    test('the base plan itself is never mistaken for an offer', () {
      final basePlanOnly = _play('pro_yearly', 999, options: [
        SubscriptionOption('base', 'pro_yearly', 'pro_yearly', [full], const ['pro_yearly_40off'], true, null, false, full, null, null, null, null),
      ]);
      expect(couponOfferFrom(_base(basePlanOnly), _coupon(), product: basePlanOnly, android: true), isNull);
    });

    test('a code for another plan does not re-price this one', () {
      expect(couponOfferFrom(_base(product, yearly: false), _coupon(), product: product, android: true), isNull);
      expect(couponOfferFrom(_base(product), _coupon(tier: Tier.superTier), product: product, android: true), isNull);
    });

    test('an offer with no intro phase is priced at what it recurs at', () {
      final flat = _play('pro_yearly', 999, options: [
        _option('offer', 'pro_yearly', tags: ['pro_yearly_40off'], full: PricingPhase(_period(PeriodUnit.year, 1, 'P1Y'), RecurrenceMode.infiniteRecurring, null, _inr(699), null)),
      ]);
      final o = couponOfferFrom(_base(flat), _coupon(), product: flat, android: true);
      expect(o!.priceString, '₹699');
    });
  });

  group('couponOfferFrom on the App Store', () {
    const product = StoreProduct(
      'pro_yearly',
      '',
      '',
      999,
      '₹999',
      'INR',
      discounts: [StoreProductDiscount('pro_yearly_40off', 599, '₹599', 1, 'P1Y', 'YEAR', 1)],
    );

    test('the promotional offer is found by its identifier and priced by the store', () {
      final o = couponOfferFrom(_base(product), _coupon(), product: product, android: false);
      expect(o!.priceString, '₹599');
      expect(o.fullPriceString, '₹999');
      expect(o.discount?.identifier, 'pro_yearly_40off');
      expect(o.subscriptionOption, isNull);
    });

    test('an identifier the product does not carry yields nothing', () {
      expect(couponOfferFrom(_base(product), _coupon(ios: 'nope'), product: product, android: false), isNull);
    });
  });
}
