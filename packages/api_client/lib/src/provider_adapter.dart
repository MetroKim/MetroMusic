/// Breezze provider adapter contract — spec §52.2.
///
/// A metadata API does NOT grant streaming rights (§52 rule). Adapters
/// normalize external responses into Breezze domain models and must
/// return an explicit unsupported result, never a fake URL.
library;

/// Normalized track reference. Canonical Breezze IDs are internal UUIDs;
/// provider IDs live only in mapping tables (§52.3).
class ProviderTrack {
  final String breezzeTrackId;
  final String providerTrackId;
  final String title;
  final String artist;
  final String? artworkUrl;
  final Duration duration;

  ProviderTrack({
    required this.breezzeTrackId,
    required this.providerTrackId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.duration,
  });
}

/// Explicit operation results — never fake a capability (§52.2).
sealed class ProviderOp<T> {}

class ProviderOk<T> extends ProviderOp<T> {
  final T value;
  ProviderOk(this.value);
}

class ProviderUnsupported<T> extends ProviderOp<T> {
  final String reason;
  ProviderUnsupported(this.reason);
}

class ProviderError<T> extends ProviderOp<T> {
  final String code;
  ProviderError(this.code);
}

/// Every adapter must report capabilities and attribution (§52.2).
abstract interface class ProviderAdapter {
  String get providerId;
  String get adapterVersion;

  /// Whether this provider is authorized for full-track playback at all.
  /// Defaults to false: metadata is not a license (§52.1).
  bool get supportsPlayback;

  Future<ProviderOp<List<ProviderTrack>>> search(String query);

  Future<ProviderOp<ProviderTrack>> getTrack(String providerTrackId);

  /// Only meaningful when [supportsPlayback] is true and the backend
  /// rights check passed; otherwise returns [ProviderUnsupported].
  Future<ProviderOp<String>> resolvePlayback(
      String providerTrackId, ProviderUserContext userContext);

  /// Attribution the UI must display when content from this provider is
  /// shown (§52.2, §36.2).
  Future<ProviderOp<String>> getAttributionRequirements(String providerTrackId);
}

/// Server-side context for entitlement decisions (§52.4).
class ProviderUserContext {
  final String userId;
  final String territory;
  final String subscriptionTier;

  ProviderUserContext({
    required this.userId,
    required this.territory,
    required this.subscriptionTier,
  });
}
