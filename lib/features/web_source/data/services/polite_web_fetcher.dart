import 'package:http/http.dart' as http;
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';

/// A descriptive identity for this app. It never impersonates a crawler
/// identity that a target site's `robots.txt` disallows.
const String voxNovelUserAgent =
    'VoxNovel/1.0 (leitor pessoal de novels; Flutter)';

/// One completed HTTP exchange, expressed without `package:http` types.
///
/// This is what keeps AD-010 enforceable: `polite_web_fetcher.dart` is the only
/// file in the project — production or test — that needs `package:http`.
final class HttpExchange {
  const HttpExchange({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;

  /// Response headers with lower-case names, as `package:http` delivers them.
  final Map<String, String> headers;
  final String body;
}

/// Performs one HTTP `GET` and does **not** follow redirects, so the fetcher
/// can inspect every hop's host before continuing.
typedef HttpSend =
    Future<HttpExchange> Function(Uri url, Map<String, String> headers);

typedef WebFetcherClock = DateTime Function();
typedef WebFetcherDelay = Future<void> Function(Duration duration);

/// The only component that touches the network.
///
/// Enforces at most one request per second per host, honors `Retry-After` on
/// `429`/`503`, retries transient failures with bounded exponential backoff,
/// and abandons redirects that leave the requested host.
final class PoliteWebFetcher implements WebFetcher {
  PoliteWebFetcher({
    HttpSend? send,
    WebFetcherClock? clock,
    WebFetcherDelay? delay,
  }) : _send = send ?? _httpSend,
       _clock = clock ?? DateTime.now,
       _delay = delay ?? _sleep;

  static const Duration minimumHostInterval = Duration(seconds: 1);
  static const int maximumAttempts = 4;
  static const Duration initialBackoff = Duration(seconds: 1);
  static const int maximumRedirects = 5;

  static const Set<int> _redirectStatuses = {301, 302, 303, 307, 308};

  final HttpSend _send;
  final WebFetcherClock _clock;
  final WebFetcherDelay _delay;
  final Map<String, DateTime> _lastRequestAt = {};

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    var backoff = initialBackoff;
    for (var attempt = 1; ; attempt++) {
      final outcome = await _attempt(url);
      if (!outcome.retryable || attempt == maximumAttempts) {
        return outcome.result;
      }
      if (outcome.retryAfter != null) {
        await _delay(outcome.retryAfter!);
      } else {
        await _delay(backoff);
        backoff *= 2;
      }
    }
  }

  Future<_Attempt> _attempt(Uri url) async {
    var current = url;
    for (var hop = 0; hop <= maximumRedirects; hop++) {
      await _throttle(current.host);

      final HttpExchange exchange;
      try {
        exchange = await _send(current, const {'User-Agent': voxNovelUserAgent});
      } on Exception catch (error) {
        return _Attempt.retryable(
          WebFetchFailed(
            WebFetchFailureKind.network,
            'Falha de rede ao acessar $current: $error',
          ),
        );
      }

      final status = exchange.statusCode;
      if (status >= 200 && status < 300) {
        return _Attempt.done(
          WebFetchSucceeded(url: current, body: exchange.body),
        );
      }

      if (_redirectStatuses.contains(status)) {
        final location = exchange.headers['location'];
        if (location == null || location.trim().isEmpty) {
          return _Attempt.done(
            WebFetchFailed(
              WebFetchFailureKind.http,
              'Redirecionamento $status sem destino em $current',
              statusCode: status,
            ),
          );
        }
        final target = current.resolve(location.trim());
        if (_canonicalHost(target.host) != _canonicalHost(url.host)) {
          return _Attempt.done(
            WebFetchFailed(
              WebFetchFailureKind.offDomain,
              'Redirecionamento para outro domínio: ${target.host}',
            ),
          );
        }
        current = target;
        continue;
      }

      if (status == 404) {
        return _Attempt.done(
          WebFetchFailed(
            WebFetchFailureKind.notFound,
            'Página não encontrada: $current',
            statusCode: status,
          ),
        );
      }

      if (status == 429 || status == 503) {
        return _Attempt.retryable(
          WebFetchFailed(
            WebFetchFailureKind.http,
            'O site pediu para aguardar (HTTP $status)',
            statusCode: status,
          ),
          retryAfter: _retryAfter(exchange.headers),
        );
      }

      if (status >= 500) {
        return _Attempt.retryable(
          WebFetchFailed(
            WebFetchFailureKind.http,
            'Erro temporário do site (HTTP $status)',
            statusCode: status,
          ),
        );
      }

      return _Attempt.done(
        WebFetchFailed(
          WebFetchFailureKind.http,
          'Resposta inesperada do site (HTTP $status)',
          statusCode: status,
        ),
      );
    }

    return _Attempt.done(
      WebFetchFailed(
        WebFetchFailureKind.http,
        'Excesso de redirecionamentos a partir de $url',
      ),
    );
  }

  Future<void> _throttle(String host) async {
    final key = _canonicalHost(host);
    final last = _lastRequestAt[key];
    if (last != null) {
      final elapsed = _clock().difference(last);
      if (elapsed < minimumHostInterval) {
        await _delay(minimumHostInterval - elapsed);
      }
    }
    _lastRequestAt[key] = _clock();
  }

  static Duration? _retryAfter(Map<String, String> headers) {
    final raw = headers['retry-after'];
    if (raw == null) {
      return null;
    }
    final seconds = int.tryParse(raw.trim());
    if (seconds == null || seconds < 0) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  static String _canonicalHost(String host) {
    final lower = host.toLowerCase();
    return lower.startsWith('www.') ? lower.substring(4) : lower;
  }
}

final class _Attempt {
  const _Attempt.done(this.result) : retryable = false, retryAfter = null;
  const _Attempt.retryable(this.result, {this.retryAfter}) : retryable = true;

  final WebFetchResult result;
  final bool retryable;
  final Duration? retryAfter;
}

Future<void> _sleep(Duration duration) => Future<void>.delayed(duration);

final http.Client _client = http.Client();

Future<HttpExchange> _httpSend(Uri url, Map<String, String> headers) async {
  final request = http.Request('GET', url)
    ..followRedirects = false
    ..headers.addAll(headers);
  final response = await http.Response.fromStream(await _client.send(request));
  return HttpExchange(
    statusCode: response.statusCode,
    headers: response.headers,
    body: response.body,
  );
}
