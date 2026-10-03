// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'web_file_picker_stub.dart';

Future<PickedFilePayload?> pickFileFromWeb() {
  final completer = Completer<PickedFilePayload?>();
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = 'image/*';
  input.style.display = 'none';
  web.document.body?.appendChild(input);

  input.onchange = (web.Event e) {
    final files = input.files;
    if (files == null || files.length == 0) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.item(0)!;
    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final result = reader.result;
      if (result != null) {
        final jsBuf = result as JSArrayBuffer;
        final bytes = jsBuf.toDart.asUint8List();
        input.remove();
        if (!completer.isCompleted) {
          completer.complete(PickedFilePayload(bytes: bytes, name: file.name));
        }
      } else {
        input.remove();
        if (!completer.isCompleted) completer.complete(null);
      }
    }.toJS;
    reader.onerror = (web.Event _) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
    }.toJS;
    reader.readAsArrayBuffer(file);
  }.toJS;

  input.oncancel = (web.Event _) {
    input.remove();
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;

  input.click();
  return completer.future;
}

Future<List<PickedFilePayload>> pickMultipleFilesFromWeb() {
  final completer = Completer<List<PickedFilePayload>>();
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = 'image/*';
  input.multiple = true;
  input.style.display = 'none';
  web.document.body?.appendChild(input);

  input.onchange = (web.Event e) {
    final files = input.files;
    if (files == null || files.length == 0) {
      input.remove();
      if (!completer.isCompleted) completer.complete([]);
      return;
    }

    final List<PickedFilePayload> results = [];
    int readCount = 0;
    final total = files.length;

    for (int i = 0; i < total; i++) {
      final file = files.item(i)!;
      final reader = web.FileReader();
      reader.onload = (web.Event _) {
        final result = reader.result;
        if (result != null) {
          final jsBuf = result as JSArrayBuffer;
          results.add(PickedFilePayload(bytes: jsBuf.toDart.asUint8List(), name: file.name));
        }
        readCount++;
        if (readCount == total) {
          input.remove();
          if (!completer.isCompleted) completer.complete(results);
        }
      }.toJS;
      reader.onerror = (web.Event _) {
        readCount++;
        if (readCount == total) {
          input.remove();
          if (!completer.isCompleted) completer.complete(results);
        }
      }.toJS;
      reader.readAsArrayBuffer(file);
    }
  }.toJS;

  input.oncancel = (web.Event _) {
    input.remove();
    if (!completer.isCompleted) completer.complete([]);
  }.toJS;

  input.click();
  return completer.future;
}
