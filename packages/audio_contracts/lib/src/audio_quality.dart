/// Breezze audio quality tiers — spec §9.6/§53.7.
///
/// Labels must reflect the actual delivered stream. Never upsample a lossy
/// source and label it lossless (§53.7).
enum AudioQualityTier {
  low('AAC · 96 kbps', false, 96),
  standard('AAC · 160 kbps', false, 160),
  high('AAC · 256 kbps', false, 256),
  lossless('Lossless · FLAC/ALAC 44.1 kHz', true, 1411),
  hiRes('Hi-Res Lossless · up to 192 kHz', true, 4608);

  const AudioQualityTier(this.label, this.isLossless, this.approxKbps);

  final String label;

  /// True only for genuinely lossless delivery.
  final bool isLossless;

  /// Approximate bitrate in kbps, used for network ceilings (§19.2).
  final int approxKbps;
}
