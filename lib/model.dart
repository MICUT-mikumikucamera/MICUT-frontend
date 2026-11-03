import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class PhotoEntry {
  PhotoEntry({
    required this.id,
    required this.path,
    required this.date,
    this.demo = false,
  });
  final String id, path;
  final DateTime date;
  final bool demo;
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'date': date.toIso8601String(),
    'demo': demo,
  };
  factory PhotoEntry.fromJson(Map<String, dynamic> json) => PhotoEntry(
    id: json['id'],
    path: json['path'],
    date: DateTime.parse(json['date']),
    demo: json['demo'] == true,
  );
}

class AppModel extends ChangeNotifier {
  AppModel(
    this.api,
    this.preferences, {
    this.pollInterval = const Duration(milliseconds: 1500),
  });
  final JobsApi api;
  final SharedPreferences preferences;
  final Duration pollInterval;
  Job? job;
  Capture? capture;
  List<PhotoEntry> photos = [];
  String? error;
  bool busy = false, _disposed = false, _foreground = true;
  Timer? _timer;
  String get _scope => 'micut.v0.${api.demo ? 'demo' : api.baseUrl}';
  bool get hasWork => job != null;

  Future<void> initialize() async {
    try {
      photos =
          (jsonDecode(preferences.getString('$_scope.photos') ?? '[]') as List)
              .map((e) => PhotoEntry.fromJson(e as Map<String, dynamic>))
              .toList();
      final saved = preferences.getString('$_scope.job');
      if (saved != null) job = Job(jsonDecode(saved));
    } catch (_) {
      error = '저장된 기록 일부를 읽지 못했어요.';
    }
    _emit();
    if (job?.active == true) await refresh();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void setCapture(Capture value) {
    capture = value;
    error = null;
    _emit();
  }

  void clearCapture() {
    capture = null;
    error = null;
    _emit();
  }

  Future<void> _persistJob() async {
    final ok = job == null
        ? await preferences.remove('$_scope.job')
        : await preferences.setString('$_scope.job', jsonEncode(job!.json));
    if (!ok) throw const ApiFailure('진행 상태를 기기에 저장하지 못했어요. 앱을 닫지 말아 주세요.');
  }

  Future<void> _accept(Job value) async {
    job = value;
    await _persistJob();
    if (value.status == 'done' && !photos.any((p) => p.id == value.id)) {
      final updated = [
        PhotoEntry(
          id: value.id,
          path: value.imagePath!,
          date: DateTime.now(),
          demo: api.demo,
        ),
        ...photos,
      ];
      if (!await preferences.setString(
        '$_scope.photos',
        jsonEncode(updated.map((p) => p.toJson()).toList()),
      )) {
        throw const ApiFailure('갤러리에 기록하지 못했어요. 결과를 다시 확인해 주세요.');
      }
      photos = updated;
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (busy || _disposed) return;
    _timer?.cancel();
    busy = true;
    error = null;
    _emit();
    try {
      await action();
    } catch (e) {
      error = e is ApiFailure ? e.message : '작업을 완료하지 못했어요. 다시 확인해 주세요.';
    } finally {
      busy = false;
      _emit();
      if (!_disposed && _foreground && job?.active == true && error == null) {
        _timer = Timer(pollInterval, refresh);
      }
    }
  }

  Future<void> create() => _perform(() async {
    if (capture == null || job != null) return;
    await _accept(await api.create(capture!));
  });
  Future<void> refresh() => _perform(() async {
    if (job != null) await _accept(await api.get(job!.id));
  });
  Future<void> retry() => _perform(() async {
    if (job != null) await _accept(await api.retry(job!));
  });
  Future<void> leaveResult() => _perform(() async {
    if (job?.active == true) return;
    if (job?.status == 'failed') await api.discard(job!);
    job = null;
    capture = null;
    await _persistJob();
  });
  Future<void> deletePhotos(Set<String> ids) async {
    final updated = photos.where((p) => !ids.contains(p.id)).toList();
    if (!await preferences.setString(
      '$_scope.photos',
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    )) {
      throw const ApiFailure('사진을 삭제하지 못했어요. 다시 시도해 주세요.');
    }
    photos = updated;
    _emit();
  }

  void setForeground(bool value) {
    _foreground = value;
    _timer?.cancel();
    if (value && job?.active == true && !busy) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    api.close();
    super.dispose();
  }
}
