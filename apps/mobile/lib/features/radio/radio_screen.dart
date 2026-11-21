import 'dart:convert';

import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/auth/auth_session.dart';
import '../../widgets/bz_brand_icons.dart';

class _RadioStation {
  final String id;
  final String name;
  final String? description;
  final String? genre;
  final bool isLive;

  const _RadioStation({
    required this.id,
    required this.name,
    this.description,
    this.genre,
    required this.isLive,
  });

  factory _RadioStation.fromJson(Map<String, dynamic> json) => _RadioStation(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled station',
        description: json['description'] as String?,
        genre: json['genre'] as String?,
        isLive: json['isLive'] == true,
      );
}

class _RadioProgram {
  final String title;
  final String? presenter;
  final DateTime? airsAt;
  final int durationMin;

  const _RadioProgram({
    required this.title,
    this.presenter,
    this.airsAt,
    required this.durationMin,
  });

  factory _RadioProgram.fromJson(Map<String, dynamic> json) => _RadioProgram(
        title: json['title'] as String? ?? 'Untitled program',
        presenter: json['presenter'] as String?,
        airsAt: DateTime.tryParse(json['airsAt'] as String? ?? ''),
        durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
      );
}

/// Radio station directory backed by the existing public radio API.
/// The current player resolves music tracks, not station streams, so this
/// screen intentionally exposes station information without fake play controls.
class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  List<_RadioStation> _stations = [];
  bool _loading = true;
  String? _error;
  int _stationsRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStations());
  }

  Future<void> _loadStations() async {
    if (!mounted) return;
    final requestGeneration = ++_stationsRequestGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(authSessionProvider.notifier).api;
      final response = await http
          .get(Uri.parse('${api.baseUrl}/api/v1/radio/stations'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) {
        throw Exception('Radio API returned ${response.statusCode}');
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic>
          ? decoded['data'] ?? decoded
          : decoded;
      if (payload is! List) {
        throw const FormatException('Invalid radio station response');
      }

      final stations = payload
          .whereType<Map>()
          .map((item) => _RadioStation.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((station) => station.id.isNotEmpty)
          .toList();

      if (!mounted || requestGeneration != _stationsRequestGeneration) return;
      setState(() {
        _stations = stations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestGeneration != _stationsRequestGeneration) return;
      setState(() {
        _loading = false;
        _error = 'Radio stations could not be loaded. Check your connection.';
      });
    }
  }

  Future<List<_RadioProgram>> _loadPrograms(
    String baseUrl,
    String stationId,
  ) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/radio/stations/$stationId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode >= 400) {
      throw Exception('Station detail unavailable');
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    final payload = decoded is Map<String, dynamic>
        ? decoded['data'] ?? decoded
        : decoded;
    final rawPrograms =
        payload is Map<String, dynamic> ? payload['programs'] : null;
    if (rawPrograms is! List) return const [];
    return rawPrograms
        .whereType<Map>()
        .map((item) => _RadioProgram.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> _showStation(_RadioStation station) async {
    final api = ref.read(authSessionProvider.notifier).api;
    final programs = _loadPrograms(api.baseUrl, station.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: FutureBuilder<List<_RadioProgram>>(
            future: programs,
            builder: (context, snapshot) {
              final theme = Theme.of(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name, style: theme.textTheme.headlineSmall),
                  if (station.genre != null) ...[
                    const SizedBox(height: 4),
                    Text(station.genre!, style: theme.textTheme.bodyMedium),
                  ],
                  if (station.description != null) ...[
                    const SizedBox(height: 12),
                    Text(station.description!),
                  ],
                  const SizedBox(height: 20),
                  Text('PROGRAM SCHEDULE', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError)
                    const Text('The station schedule could not be loaded.')
                  else if (snapshot.data == null || snapshot.data!.isEmpty)
                    const Text('No program schedule is available yet.')
                  else
                    ...snapshot.data!.map((program) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(program.title),
                          subtitle: Text([
                            if (program.presenter != null) program.presenter!,
                            if (program.airsAt != null)
                              program.airsAt!.toLocal().toString(),
                            if (program.durationMin > 0)
                              '${program.durationMin} min',
                          ].join(' · ')),
                        )),
                  const SizedBox(height: 8),
                  Text(
                    'Station playback will be enabled when the radio stream '
                    'is integrated with the playback engine.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stationsRequestGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Radio', style: theme.textTheme.displayMedium),
                const SizedBox(height: 6),
                Text('Stations and programs.', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _loadStations,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _stations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BzBnoteMark(size: 56, color: theme.bzText2),
                                const SizedBox(height: 12),
                                Text('No stations available',
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 220),
                            itemCount: _stations.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: theme.bzSeparator, height: 1),
                            itemBuilder: (context, index) {
                              final station = _stations[index];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.bzSurface1,
                                    borderRadius: BorderRadius.circular(
                                        BzRadius.artwork),
                                  ),
                                  child: Icon(Icons.radio,
                                      color: theme.bzText2),
                                ),
                                title: Text(station.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  [if (station.genre != null) station.genre!,
                                   if (station.description != null)
                                     station.description!].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: station.isLive
                                    ? const Chip(
                                        label: Text('LIVE'),
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: () => _showStation(station),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
