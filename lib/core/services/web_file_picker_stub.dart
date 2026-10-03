import 'dart:typed_data';

class PickedFilePayload {
  final Uint8List bytes;
  final String name;

  PickedFilePayload({required this.bytes, required this.name});
}

Future<PickedFilePayload?> pickFileFromWeb() async => null;
Future<List<PickedFilePayload>> pickMultipleFilesFromWeb() async => [];
