import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:path/path.dart' as pathlib;

class UIDataService {

  UIDataService();
  late String _thumbnailBase;

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    final base = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
    _thumbnailBase = pathlib.join(base, 'Moxxy', '.thumbnail');
  }

  // The base path for thumbnails
  String get thumbnailBase => _thumbnailBase;

  /// Returns the path of a possible thumbnail for the video. Does not imply that the file
  /// exists.
  String getThumbnailPath(Message message) => getThumbnailPathFull(
    message.conversationJid,
    pathlib.basename(message.mediaUrl!),
  );

  /// Returns the path of a possible thumbnail for the video. Does not imply that the file
  /// exists.
  String getThumbnailPathFull(String conversationJid, String filename) => pathlib.join(
    _thumbnailBase,
    conversationJid,
    filename,
  );

}
