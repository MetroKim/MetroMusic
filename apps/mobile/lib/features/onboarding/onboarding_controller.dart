import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/api/breezze_api.dart';
import '../core/auth/auth_session.dart';

/// Onboarding state machine: collects country, genres, and favorite
/// artists, then POSTs once to /onboarding/preferences.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setCountry(String country) =>
      state = state.copyWith(country: country);

  void toggleGenre(String genre) {
    final genres = {...state.genres};
    genres.contains(genre) ? genres.remove(genre) : genres.add(genre);
    state = state.copyWith(genres: genres);
  }

  void toggleArtist(String artist) {
    final artists = {...state.favoriteArtists};
    artists.contains(artist)
        ? artists.remove(artist)
        : artists.add(artist);
    state = state.copyWith(favoriteArtists: artists);
  }

  /// Persists preferences to the backend. Returns true on success.
  Future<bool> save(BreezzeApi api) async {
    state = state.copyWith(saving: true);
    try {
      final res = await http.post(
        Uri.parse('${api.baseUrl}/api/v1/onboarding/preferences'),
        headers: {
          'Content-Type': 'application/json',
          if (api.accessToken != null)
            'Authorization': 'Bearer ${api.accessToken}',
        },
        body: jsonEncode({
          'country': state.country,
          'genres': state.genres.toList(),
          'favoriteArtists': state.favoriteArtists.toList(),
        }),
      );
      state = state.copyWith(saving: false);
      return res.statusCode < 400;
    } catch (_) {
      state = state.copyWith(saving: false);
      return false;
    }
  }
}

class OnboardingState {
  final String country;
  final Set<String> genres;
  final Set<String> favoriteArtists;
  final bool saving;

  const OnboardingState({
    this.country = '',
    this.genres = const {},
    this.favoriteArtists = const {},
    this.saving = false,
  });

  OnboardingState copyWith({
    String? country,
    Set<String>? genres,
    Set<String>? favoriteArtists,
    bool? saving,
  }) =>
      OnboardingState(
        country: country ?? this.country,
        genres: genres ?? this.genres,
        favoriteArtists: favoriteArtists ?? this.favoriteArtists,
        saving: saving ?? this.saving,
      );

  bool get canFinish =>
      country.isNotEmpty && genres.length >= 3 && !saving;
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

/// Genre taxonomy (plan §4.3) — illustrative top-level set, the
/// backend genre tree extends this.
const kOnboardingGenres = [
  'Pop', 'Hip-Hop / Rap', 'Electronic', 'Rock', 'Jazz', 'R&B',
  'Classical', 'Country', 'Reggae', 'Gospel', 'Afrobeat',
  'Amapiano', 'World Music',
];

/// Country list — compact ISO display list.
const kOnboardingCountries = [
  'IN', 'US', 'GB', 'CA', 'AU', 'DE', 'FR', 'ES', 'IT', 'NL',
  'SE', 'NO', 'BR', 'MX', 'JP', 'KR', 'CN', 'ZA', 'NG', 'KE',
  'AE', 'SA', 'SG', 'MY', 'ID', 'PH', 'VN', 'TH', 'PK', 'BD',
];

String countryName(String code) {
  const names = {
    'IN': 'India', 'US': 'United States', 'GB': 'United Kingdom',
    'CA': 'Canada', 'AU': 'Australia', 'DE': 'Germany', 'FR': 'France',
    'ES': 'Spain', 'IT': 'Italy', 'NL': 'Netherlands', 'SE': 'Sweden',
    'NO': 'Norway', 'BR': 'Brazil', 'MX': 'Mexico', 'JP': 'Japan',
    'KR': 'South Korea', 'CN': 'China', 'ZA': 'South Africa',
    'NG': 'Nigeria', 'KE': 'Kenya', 'AE': 'UAE', 'SA': 'Saudi Arabia',
    'SG': 'Singapore', 'MY': 'Malaysia', 'ID': 'Indonesia',
    'PH': 'Philippines', 'VN': 'Vietnam', 'TH': 'Thailand',
    'PK': 'Pakistan', 'BD': 'Bangladesh',
  };
  return names[code] ?? code;
}

/// Convenience access to the authenticated api client.
BreezzeApi authenticatedApi(Ref ref) =>
    ref.read(authSessionProvider.notifier).api;
