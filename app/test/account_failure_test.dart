// A failed profile load is not a Free plan: paying readers keep their perks
// and aren't sold what they already have.

import 'dart:convert';
import 'dart:typed_data';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/data/account.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/ads/ads.dart';
import 'package:arth/features/community/community_lock.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _User implements User {
  @override
  String get uid => 'u';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// /me: fails [failures] times, then answers with a Super account.
class _Server implements HttpClientAdapter {
  _Server(this.failures, {this.tier = 'super'});

  final String tier;
  int failures;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    if (options.path == '/sync') {
      return _json({'cursor': 0, 'more': false, 'cards': <Object>[], 'bookmarks': <Object>[]});
    }
    if (failures > 0) {
      failures--;
      throw DioException.connectionTimeout(timeout: const Duration(seconds: 6), requestOptions: options);
    }
    return _json({'uid': 'u', 'tier': tier});
  }

  ResponseBody _json(Map<String, Object> data) => ResponseBody.fromString(jsonEncode({'ok': true, 'data': data}), 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

class _Ready extends AdsReady {
  @override
  bool build() => true;
}

ProviderContainer _container(_Server server, {List<Override> extra = const []}) {
  final container = ProviderContainer(
    overrides: [
      signedInUidProvider.overrideWithValue('u'),
      authUserProvider.overrideWith((_) => Stream.value(_User())),
      apiClientProvider.overrideWithValue(ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://test/v1'))..httpClientAdapter = server)),
      accountRetryDelaysProvider.overrideWithValue(const [Duration.zero, Duration.zero]),
      adsReadyProvider.overrideWith(_Ready.new),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed first load is retried, and the plan arrives', () async {
    final server = _Server(2);
    final container = _container(server);
    final account = await container.read(accountProvider.future);
    expect(account?.tier, Tier.superTier);
    expect(server.calls, 3);
    expect(container.read(communityAccessProvider), CommunityAccess.open);
    expect(container.read(showAdsProvider), isFalse);
  });

  group('when the account will not load', () {
    late ProviderContainer container;

    setUp(() async {
      container = _container(_Server(3));
      await expectLater(container.read(accountProvider.future), throwsA(isA<ApiFailure>()));
    });

    test('the community neither opens nor sells a plan', () {
      expect(container.read(communityAccessProvider), CommunityAccess.unknown);
    });

    test('no ads', () {
      expect(container.read(showAdsProvider), isFalse);
    });
  });

  test('a successful sync reloads a profile that failed', () async {
    sqfliteFfiInit();
    final path = '${await databaseFactoryFfi.getDatabasesPath()}/account_failure_test.db';
    await databaseFactoryFfi.deleteDatabase(path);
    final store = await LocalStore.openAt(path, factory: databaseFactoryFfi);

    final server = _Server(3);
    final container = _container(server, extra: [localStoreProvider.overrideWithValue(store)]);
    await expectLater(container.read(accountProvider.future), throwsA(isA<ApiFailure>()));
    expect(container.read(communityAccessProvider), CommunityAccess.unknown);

    await container.read(syncProvider.notifier).run();

    expect((await container.read(accountProvider.future))?.tier, Tier.superTier);
    expect(container.read(communityAccessProvider), CommunityAccess.open);
  });

  test('ads: not before sign-in is restored, then signed out yes', () async {
    final container = ProviderContainer(
      overrides: [
        signedInUidProvider.overrideWithValue(null),
        authUserProvider.overrideWith((_) => Stream.value(null)),
        adsReadyProvider.overrideWith(_Ready.new),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(showAdsProvider), isFalse);
    await container.read(authUserProvider.future);
    expect(container.read(showAdsProvider), isTrue);
  });

  test('ads: a Free account sees them', () async {
    final container = _container(_Server(0, tier: 'free'));
    await container.read(accountProvider.future);
    expect(container.read(showAdsProvider), isTrue);
  });
}
