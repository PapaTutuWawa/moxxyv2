import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

/// Save the bytes [bytes] that represent the user's avatar under
/// the [cache directory]/users/[jid]/avatar_[hash].png.
/// [cache directory] is provided by path_provider.
Future<String> saveAvatarInCache(List<int> bytes, String hash, String jid, String oldPath) async {
  final cacheDir = (await getApplicationDocumentsDirectory()).path;
  final avatarsDir = Directory(pathlib.join(cacheDir, 'avatars'));
  await avatarsDir.create(recursive: true);

  if (oldPath.isNotEmpty) {
    final oldAvatar = File(oldPath);
    if (oldAvatar.existsSync()) await oldAvatar.delete();
  }

  final avatarPath = pathlib.join(avatarsDir.path, '$hash.png');
  await File(avatarPath).writeAsBytes(bytes);

  return avatarPath;
}

/// Returns the path where a user's avatar is saved. Note that this does not imply
/// the existence of an avatar.
Future<String> getAvatarPath(String jid, String hash) async {
  final cacheDir = (await getApplicationDocumentsDirectory()).path;
  return pathlib.join(cacheDir, 'avatars', '$hash.png');
}
