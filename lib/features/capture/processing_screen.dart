import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';
import 'capture_view.dart';
import 'person_picker.dart';

/// 04 처리 중. 계약 2026-11-18 부터 중간에 `awaiting_person` 이 오면
/// 03 촬영 확인 화면 틀을 재활용해 "누구를 따라할지"를 고른 뒤 다시 처리 중으로 돌아간다.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  StreamSubscription<Job>? _sub;
  bool _connectionFailed = false;

  /// awaiting_person 으로 멈춘 Job. null 이면 일반 처리 중 화면.
  Job? _awaiting;
  String? _selectedId;
  bool _submitting = false;
  String? _selectError;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    _sub?.cancel();
    setState(() => _connectionFailed = false);
    _sub = ref.read(jobRepositoryProvider).watch(widget.jobId).listen((job) {
      if (!mounted) return;
      if (job.status == JobStatus.done) {
        context.pushReplacement(Routes.resultOf(job.jobId));
      } else if (job.status == JobStatus.failed) {
        context.pushReplacement(Routes.failedOf(job.jobId));
      } else if (job.status == JobStatus.awaitingPerson) {
        _showPicker(job);
      }
    }, onError: (_) {
      if (mounted) setState(() => _connectionFailed = true);
    });
  }

  /// 접수 때 앱이 보낸 크기·크롭. 없으면 서버 응답의 capture.
  CaptureInfo _capture(Job job) =>
      ref.read(captureInfoProvider(widget.jobId)) ?? job.capture;

  /// 크롭 화면에 보이는 사람만. 크롭 밖 사람은 결과에도 안 나오므로 뺀다.
  List<PersonInCrop> _visiblePeople(Job job) {
    final capture = _capture(job);
    return peopleInCrop(job.people?.people ?? const [],
        imageWidth: capture.w, imageHeight: capture.h, crop: capture.crop);
  }

  void _showPicker(Job job) {
    final eligible = _visiblePeople(job)
        .map((p) => p.person)
        .where((p) => p.eligible)
        .toList();
    final recommended = job.people?.recommendedPersonId;
    setState(() {
      _awaiting = job;
      _selectError = null;
      _selectedId = eligible.any((p) => p.personId == recommended)
          ? recommended
          : (eligible.isEmpty ? null : eligible.first.personId);
    });
  }

  /// [personId] null = 따라하지 않기(solo).
  Future<void> _select(String? personId) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _selectError = null;
    });
    try {
      await ref
          .read(jobRepositoryProvider)
          .selectPerson(widget.jobId, personId: personId);
      if (!mounted) return;
      setState(() => _awaiting = null);
      _watch();
    } on PersonSelectException catch (e) {
      if (!mounted) return;
      if (e.notAllowed) {
        // 이미 선택 단계가 끝난 작업 — 최신 상태로 다시 따라간다.
        setState(() => _awaiting = null);
        _watch();
      } else {
        setState(() => _selectError = '고를 수 없는 사람이에요. 다른 사람을 골라 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _selectError = '네트워크 연결을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _close() async {
    await _sub?.cancel();
    // Closing the waiting view is not a supported server cancellation operation.
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final awaiting = _awaiting;
    if (awaiting != null) return _buildPicker(awaiting);
    return CaptureView(
      photoPath: ref.watch(capturePhotoProvider(widget.jobId)),
      processing: !_connectionFailed,
      message: _connectionFailed ? '네트워크 연결을 확인해 주세요.' : '미쿠 사진을 만드는 중...',
      onClose: _close,
      actions: FractionallySizedBox(
          widthFactor: .5,
          child: MiCutButton(
            label: _connectionFailed ? '재시도' : '취소',
            type: MiCutButtonType.secondary,
            onPressed: _connectionFailed ? _watch : _close,
          )),
    );
  }

  /// 03 촬영 확인 틀 재활용. 크롭된 사진 위에 크롭 안에 있는 사람만 그린다.
  Widget _buildPicker(Job job) {
    final capture = _capture(job);
    final crop = capture.crop;
    final aspect = crop != null && crop.height > 0
        ? crop.width / crop.height
        : (capture.h > 0 ? capture.w / capture.h : 0.0);
    // 크롭 정보를 전혀 모르면(앱 재시작 등) 박스 위치를 맞출 수 없어 그리지 않는다.
    final cropKnown =
        crop != null || ref.read(captureInfoProvider(widget.jobId)) != null;
    return CaptureView(
      photoPath: ref.watch(capturePhotoProvider(widget.jobId)),
      photoOverlay: !cropKnown
          ? null
          : PersonPickerOverlay(
              aspectRatio: aspect,
              people: _visiblePeople(job),
              selectedId: _selectedId,
              onSelect: _submitting
                  ? (_) {}
                  : (id) => setState(() => _selectedId = id),
            ),
      // TODO(디자인): 안내 문구·버튼 이름은 정윤님 확정 전 임시.
      message: _selectError ?? '미쿠가 누구 포즈를 따라할까요?',
      onClose: _submitting ? null : _close,
      actions: Row(children: [
        Expanded(
            child: MiCutButton(
                label: '따라하지 않기',
                type: MiCutButtonType.secondary,
                onPressed: _submitting ? null : () => _select(null))),
        const SizedBox(width: Spacing.md),
        Expanded(
            child: MiCutButton(
                label: '따라하기',
                loading: _submitting,
                onPressed: _submitting || _selectedId == null
                    ? null
                    : () => _select(_selectedId))),
      ]),
    );
  }
}
