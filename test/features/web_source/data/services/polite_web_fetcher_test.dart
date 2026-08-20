import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/web_source/data/services/polite_web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';

/// A clock that only moves when the injected delay is awaited, so throttling
/// and `Retry-After` waits are asserted without the suite sleeping.
final class FakeClock {
  DateTime now = DateTime.utc(2026, 8, 17, 12);

  DateTime call() => now;

  Future<void> delay(Duration duration) async {
    now = now.add(duration);
  }
}

final class RecordedRequest {
  const RecordedRequest(this.url, this.headers, this.at);

  final Uri url;
  final Map<String, String> headers;
  final DateTime at;
}

/// A hand-written transport fake. It never touches the network.
final class FakeTransport {
  FakeTransport(this._clock, this._respond);

  final FakeClock _clock;
  final HttpExchange Function(Uri url, int callIndex) _respond;
  final List<RecordedRequest> requests = [];

  Future<HttpExchange> send(Uri url, Map<String, String> headers) async {
    final index = requests.length;
    requests.add(RecordedRequest(url, headers, _clock.now));
    return _respond(url, index);
  }
}

HttpExchange ok(String body) =>
    HttpExchange(statusCode: 200, headers: const {}, body: body);

HttpExchange status(int code, {Map<String, String> headers = const {}}) =>
    HttpExchange(statusCode: code, headers: headers, body: '');

HttpExchange redirect(int code, String location) =>
    HttpExchange(statusCode: code, headers: {'location': location}, body: '');

void main() {
  late FakeClock clock;
  final page = Uri.parse('https://exemplo.com/series/obra/capitulo-1/');

  setUp(() => clock = FakeClock());

  PoliteWebFetcher fetcherFor(FakeTransport transport) => PoliteWebFetcher(
    send: transport.send,
    clock: clock.call,
    delay: clock.delay,
  );

  test('returns the body of a successful response', () async {
    final transport = FakeTransport(clock, (_, _) => ok('<html>corpo</html>'));

    final result = await fetcherFor(transport).fetch(page);

    expect(result, isA<WebFetchSucceeded>());
    expect((result as WebFetchSucceeded).body, '<html>corpo</html>');
    expect(result.url, page);
  });

  test('spaces consecutive requests to one host by at least one second',
      () async {
    final transport = FakeTransport(clock, (_, _) => ok('corpo'));
    final fetcher = fetcherFor(transport);

    await fetcher.fetch(page);
    await fetcher.fetch(page.replace(path: '/series/obra/capitulo-2/'));
    await fetcher.fetch(page.replace(path: '/series/obra/capitulo-3/'));

    expect(transport.requests.length, 3);
    expect(
      transport.requests[1].at.difference(transport.requests[0].at),
      greaterThanOrEqualTo(const Duration(seconds: 1)),
    );
    expect(
      transport.requests[2].at.difference(transport.requests[1].at),
      greaterThanOrEqualTo(const Duration(seconds: 1)),
    );
  });

  test('throttles per host, not globally', () async {
    final transport = FakeTransport(clock, (_, _) => ok('corpo'));
    final fetcher = fetcherFor(transport);

    await fetcher.fetch(page);
    await fetcher.fetch(Uri.parse('https://outro.com/series/obra/'));

    expect(
      transport.requests[1].at.difference(transport.requests[0].at),
      Duration.zero,
    );
  });

  group('concurrent drains', () {
    /// Two books downloading at once share one fetcher singleton, so the host
    /// limit has to hold across callers, not just across sequential calls.
    List<Duration> gapsBetween(FakeTransport transport) => [
      for (var i = 1; i < transport.requests.length; i++)
        transport.requests[i].at.difference(transport.requests[i - 1].at),
    ];

    test('charges a full host interval to every concurrent request '
        'but the first', () async {
      final transport = FakeTransport(clock, (_, _) => ok('corpo'));
      final fetcher = fetcherFor(transport);
      final start = clock.now;

      await Future.wait([
        fetcher.fetch(page),
        fetcher.fetch(page.replace(path: '/series/obra/capitulo-2/')),
        fetcher.fetch(page.replace(path: '/series/obra/capitulo-3/')),
      ]);

      expect(transport.requests.length, 3);
      // The clock is a single virtual instant that jumps when a delay is
      // requested, so concurrent send timestamps cannot be compared directly;
      // what it does measure faithfully is the total interval the host was
      // charged. Three requests owe two intervals. While the slot was claimed
      // only after awaiting, two callers read the same timestamp and the host
      // was charged one.
      expect(
        clock.now.difference(start),
        greaterThanOrEqualTo(const Duration(seconds: 2)),
      );
    });

    test('does not serialize concurrent requests to different '
        'hosts', () async {
      final transport = FakeTransport(clock, (_, _) => ok('corpo'));
      final fetcher = fetcherFor(transport);

      await Future.wait([
        fetcher.fetch(page),
        fetcher.fetch(Uri.parse('https://outro.com/series/obra/')),
      ]);

      expect(gapsBetween(transport), [Duration.zero]);
    });

    test('gives every concurrent request to one host its own '
        'response', () async {
      final transport = FakeTransport(
        clock,
        (url, _) => ok('corpo de ${url.path}'),
      );
      final fetcher = fetcherFor(transport);

      final results = await Future.wait([
        fetcher.fetch(page.replace(path: '/a/')),
        fetcher.fetch(page.replace(path: '/b/')),
        fetcher.fetch(page.replace(path: '/c/')),
      ]);

      expect(
        results.map((result) => (result as WebFetchSucceeded).body),
        ['corpo de /a/', 'corpo de /b/', 'corpo de /c/'],
      );
    });

    test('a Retry-After wait still outlasts the host interval when a '
        'second caller is queued', () async {
      final transport = FakeTransport(
        clock,
        (_, index) =>
            index == 0 ? status(429, headers: {'retry-after': '5'}) : ok('corpo'),
      );
      final fetcher = fetcherFor(transport);

      await Future.wait([
        fetcher.fetch(page),
        fetcher.fetch(page.replace(path: '/series/obra/capitulo-2/')),
      ]);

      final retried = transport.requests
          .where((request) => request.url == page)
          .toList();
      expect(retried.length, 2);
      expect(
        retried[1].at.difference(retried[0].at),
        greaterThanOrEqualTo(const Duration(seconds: 5)),
      );
    });
  });

  test('waits at least the Retry-After duration after a 429', () async {
    final transport = FakeTransport(
      clock,
      (_, index) => index == 0
          ? status(429, headers: const {'retry-after': '5'})
          : ok('corpo'),
    );

    final result = await fetcherFor(transport).fetch(page);

    expect(result, isA<WebFetchSucceeded>());
    expect(transport.requests.length, 2);
    expect(
      transport.requests[1].at.difference(transport.requests[0].at),
      greaterThanOrEqualTo(const Duration(seconds: 5)),
    );
  });

  test('waits at least the Retry-After duration after a 503', () async {
    final transport = FakeTransport(
      clock,
      (_, index) => index == 0
          ? status(503, headers: const {'retry-after': '7'})
          : ok('corpo'),
    );

    final result = await fetcherFor(transport).fetch(page);

    expect(result, isA<WebFetchSucceeded>());
    expect(
      transport.requests[1].at.difference(transport.requests[0].at),
      greaterThanOrEqualTo(const Duration(seconds: 7)),
    );
  });

  test('retries transient failures with exponential backoff up to the bound',
      () async {
    final transport = FakeTransport(clock, (_, _) => status(500));

    final result = await fetcherFor(transport).fetch(page);

    expect(transport.requests.length, PoliteWebFetcher.maximumAttempts);
    expect(transport.requests.length, 4);
    final gaps = [
      for (var i = 1; i < transport.requests.length; i++)
        transport.requests[i].at.difference(transport.requests[i - 1].at),
    ];
    expect(gaps, const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ]);
    expect(result, isA<WebFetchFailed>());
    expect((result as WebFetchFailed).kind, WebFetchFailureKind.http);
    expect(result.statusCode, 500);
  });

  test('surfaces a network failure after the bounded attempts', () async {
    final transport = FakeTransport(
      clock,
      (_, _) => throw const _TransportDown(),
    );

    final result = await fetcherFor(transport).fetch(page);

    expect(transport.requests.length, 4);
    expect(result, isA<WebFetchFailed>());
    expect((result as WebFetchFailed).kind, WebFetchFailureKind.network);
  });

  test('abandons a redirect that leaves the requested host', () async {
    final transport = FakeTransport(
      clock,
      (_, index) => index == 0
          ? redirect(302, 'https://outro.com/series/obra/capitulo-1/')
          : ok('corpo'),
    );

    final result = await fetcherFor(transport).fetch(page);

    expect(result, isA<WebFetchFailed>());
    expect((result as WebFetchFailed).kind, WebFetchFailureKind.offDomain);
    expect(result.message, contains('outro.com'));
    expect(transport.requests.length, 1, reason: 'the off-host URL is never requested');
  });

  test('follows a redirect that stays on the requested host', () async {
    final transport = FakeTransport(
      clock,
      (_, index) => index == 0
          ? redirect(301, '/series/obra/capitulo-1-final/')
          : ok('corpo final'),
    );

    final result = await fetcherFor(transport).fetch(page);

    expect(result, isA<WebFetchSucceeded>());
    expect((result as WebFetchSucceeded).body, 'corpo final');
    expect(result.url.path, '/series/obra/capitulo-1-final/');
  });

  test('marks a 404 as not found without retrying', () async {
    final transport = FakeTransport(clock, (_, _) => status(404));

    final result = await fetcherFor(transport).fetch(page);

    expect(transport.requests.length, 1);
    expect(result, isA<WebFetchFailed>());
    expect((result as WebFetchFailed).kind, WebFetchFailureKind.notFound);
    expect(result.statusCode, 404);
  });

  test('sends a descriptive app User-Agent on every request', () async {
    final transport = FakeTransport(
      clock,
      (_, index) => index == 0 ? status(500) : ok('corpo'),
    );

    await fetcherFor(transport).fetch(page);

    expect(transport.requests.length, 2);
    for (final request in transport.requests) {
      expect(request.headers['User-Agent'], voxNovelUserAgent);
      expect(voxNovelUserAgent, startsWith('VoxNovel/'));
    }
  });
}

final class _TransportDown implements Exception {
  const _TransportDown();

  @override
  String toString() => 'conexão indisponível';
}
