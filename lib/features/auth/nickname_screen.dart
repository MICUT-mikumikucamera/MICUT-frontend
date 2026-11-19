import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/auth/auth.dart';
import '../../data/auth/nickname_validator.dart';
import '../../data/auth/providers.dart';
import 'auth_scaffold.dart';

/// 00-1 닉네임 입력 (기본 / 사용 가능 / 에러). Figma 402:1274 · 1286 · 1366.
// TODO(디자인): 글자 수 카운터가 시안에는 `0/10`, 안내문은 2~20자라 서로 다르다. 20으로 맞췄다.
// TODO(디자인): 공백·이모지·중복 닉네임 에러 문구는 시안에 없어 임시 문구다.
class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  Timer? _timer;

  /// 지금 입력에 대한 검사 결과. 서버 확인 전이거나 입력이 비어 있으면 null.
  NicknameCheck? _check;
  bool _checking = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 약관 화면에서 뒤로 왔을 때 지금 닉네임을 채워 둔다.
    ref.read(authRepositoryProvider).nickname().then((saved) {
      if (!mounted || saved == null || _controller.text.isNotEmpty) return;
      _controller.text = saved;
      _onChanged(saved);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    if (value.isEmpty) {
      setState(() {
        _check = null;
        _checking = false;
      });
      return;
    }
    final local = validateNickname(value);
    if (local != null) {
      setState(() {
        _check = NicknameCheck(local);
        _checking = false;
      });
      return;
    }
    setState(() {
      _check = null;
      _checking = true;
    });
    _timer = Timer(_debounce, () async {
      final result =
          await ref.read(authRepositoryProvider).checkNickname(value);
      // 기다리는 사이 입력이 바뀌었으면 옛 결과는 버린다.
      if (!mounted || _controller.text != value) return;
      setState(() {
        _check = result;
        _checking = false;
      });
    });
  }

  Future<void> _next() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .saveNickname(_controller.text);
    } on ArgumentError {
      // 확인과 저장 사이에 다른 사람이 같은 닉네임을 가져간 경우.
      if (mounted) {
        setState(() => _check = const NicknameCheck(NicknameIssue.taken));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.characters.length;
    final canNext = _check?.available == true && !_checking;
    return AuthScaffold(
      title: '반가워요! Micut에서 사용하실\n닉네임을 설정해 주세요 ♬',
      subtitle: '닉네임은 2~20자까지 설정이 가능하며, 공백과 이모지는 사용할 수 없어요.',
      onBack: () => ref.read(authControllerProvider.notifier).signOut(),
      cta: AuthCta(
        label: '다음으로',
        loading: _saving,
        onPressed: canNext ? _next : null,
      ),
      child: _NicknameField(
        controller: _controller,
        length: length,
        check: _check,
        onChanged: _onChanged,
      ),
    );
  }
}

class _NicknameField extends StatelessWidget {
  const _NicknameField({
    required this.controller,
    required this.length,
    required this.check,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final NicknameCheck? check;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final issue = check?.issue;
    final lineColor =
        issue != null ? MiCutColors.danger : MiCutColors.borderDefault;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: MiCutText.body16Regular,
            cursorColor: MiCutColors.textDefault,
            // 길이 제한은 입력을 막지 않고 에러로 알려 준다(붙여넣기 대응).
            inputFormatters: [LengthLimitingTextInputFormatter(40)],
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '닉네임을 입력해 주세요',
              hintStyle: MiCutText.body16Regular
                  .copyWith(color: MiCutColors.textDisabled),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Text('$length/$nicknameMaxLength',
            style: MiCutText.detail14Regular
                .copyWith(color: MiCutColors.textSubtle)),
      ]),
      const SizedBox(height: Spacing.sm),
      DecoratedBox(
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: lineColor))),
        child: const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: Spacing.sm),
      _Message(check: check),
    ]);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.check});
  final NicknameCheck? check;

  static String _text(NicknameIssue issue) => switch (issue) {
        NicknameIssue.tooShort => '닉네임은 최소 2자로 설정해 주세요.',
        NicknameIssue.tooLong => '닉네임은 최대 20자까지 설정할 수 있어요.',
        NicknameIssue.hasWhitespace => '공백은 사용할 수 없어요.',
        NicknameIssue.hasEmoji => '이모지는 사용할 수 없어요.',
        NicknameIssue.taken => '이미 사용 중인 닉네임이에요.',
      };

  @override
  Widget build(BuildContext context) {
    final result = check;
    // 입력 전이거나 서버 확인 중에는 자리를 비워 두어 화면이 흔들리지 않게 한다.
    if (result == null) return const SizedBox(height: 20);
    final issue = result.issue;
    return Row(children: [
      Icon(issue == null ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: issue == null ? MiCutColors.success : MiCutColors.danger),
      const SizedBox(width: Spacing.s6),
      Flexible(
        child: Text(issue == null ? '사용 가능한 닉네임이에요.' : _text(issue),
            style: MiCutText.detail14Regular
                .copyWith(color: MiCutColors.textSubtle)),
      ),
    ]);
  }
}
