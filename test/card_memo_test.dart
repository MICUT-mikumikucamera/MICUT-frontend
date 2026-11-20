import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/data/local/local_store.dart';

void main() {
  test(
      'photo bytes and card memos survive a new store without crossing card IDs',
      () async {
    final dir = await Directory.systemTemp.createTemp('micut-store-test-');
    addTearDown(() => dir.delete(recursive: true));
    final first = LocalStore(directory: dir);
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWZkAAAAASUVORK5CYII=');
    final item = await first.addFromBytes(png, cardIds: ['001']);
    await first.saveCardMemo('001', '첫 촬영\n함께한 날');
    await first.saveCardMemo('002', '다른 카드');
    final reopened = LocalStore(directory: dir);
    expect(await reopened.loadCardMemo('001'), '첫 촬영\n함께한 날');
    expect(await reopened.loadCardMemo('002'), '다른 카드');
    expect(await reopened.loadCardMemo('009'), '');
    await reopened.saveCardMemo('001', '');
    expect(await reopened.loadCardMemo('001'), '');
    expect(await reopened.loadCardMemo('002'), '다른 카드');
    expect((await reopened.loadGallery()).single.id, item.id);
    expect(await File(item.path).readAsBytes(), png);
  });
}
