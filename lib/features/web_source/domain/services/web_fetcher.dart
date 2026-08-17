/// Why a fetch could not produce a page body.
enum WebFetchFailureKind {
  /// The request never completed — no response was received.
  network,

  /// The server answered, but not with a usable page.
  http,

  /// The server answered `404`.
  notFound,

  /// A redirect pointed outside the requested host.
  offDomain,
}

sealed class WebFetchResult {
  const WebFetchResult();
}

final class WebFetchSucceeded extends WebFetchResult {
  const WebFetchSucceeded({required this.url, required this.body});

  /// The URL the body actually came from, after any same-host redirects.
  final Uri url;
  final String body;
}

final class WebFetchFailed extends WebFetchResult {
  const WebFetchFailed(this.kind, this.message, {this.statusCode});

  final WebFetchFailureKind kind;
  final String message;
  final int? statusCode;
}

/// The single seam through which the application reaches the network (AD-010).
///
/// Domain services depend on this interface and never perform I/O themselves,
/// so per-host throttling and politeness cannot be bypassed.
abstract interface class WebFetcher {
  Future<WebFetchResult> fetch(Uri url);
}
