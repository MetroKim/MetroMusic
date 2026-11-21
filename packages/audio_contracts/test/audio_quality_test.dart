import 'package:breezze_audio_contracts/audio_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quality tiers expose truthful lossless metadata', () {
    expect(AudioQualityTier.low.isLossless, isFalse);
    expect(AudioQualityTier.standard.isLossless, isFalse);
    expect(AudioQualityTier.high.isLossless, isFalse);
    expect(AudioQualityTier.lossless.isLossless, isTrue);
    expect(AudioQualityTier.hiRes.isLossless, isTrue);
  });

  test('quality tiers retain their labels and bitrate ceilings', () {
    expect(AudioQualityTier.low.approxKbps, 96);
    expect(AudioQualityTier.standard.approxKbps, 160);
    expect(AudioQualityTier.high.approxKbps, 256);
    expect(AudioQualityTier.lossless.approxKbps, 1411);
    expect(AudioQualityTier.hiRes.approxKbps, 4608);
  });
}
