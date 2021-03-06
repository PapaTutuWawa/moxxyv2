import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';

/// Shows a dialog asking the user if they are sure that they want to proceed with an
/// action.
Future<void> showConfirmationDialog(String title, String body, BuildContext context, void Function() callback) async {
  await showDialog<dynamic>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: callback,
          child: const Text('Yes'),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('No'),
        )
      ],
    ),
  );
}

/// Shows a dialog telling the user that the [feature] feature is not implemented.
Future<void> showNotImplementedDialog(String feature, BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Not Implemented'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('The $feature feature is not yet implemented.')
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    },
  );
}

/// Dismissed the softkeyboard.
void dismissSoftKeyboard(BuildContext context) {
  // NOTE: Thank you, https://flutterigniter.com/dismiss-keyboard-form-lose-focus/
  final current = FocusScope.of(context);
  if (!current.hasPrimaryFocus) {
    current.unfocus();
  }
}

/// Open the file picker to pick an image and open the cropping tool.
/// The Future either resolves to null if the user cancels the action or
/// the actual image data.
Future<Uint8List?> pickAndCropImage(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null) {
    return GetIt.I.get<CropBloc>().cropImageWithData(result.files.single.bytes!);
  }

  return null;
}

class PickedAvatar {

  const PickedAvatar(this.path, this.hash);
  final String path;
  final String hash;
}

/// Open the file picker to pick an image, open the cropping tool and then save it.
/// [oldPath] is the path of the old avatar or "" if none has been set.
/// Returns the path of the new avatar path.
Future<PickedAvatar?> pickAvatar(BuildContext context, String jid, String oldPath) async {
  final data = await pickAndCropImage(context);

  if (data != null) {
    // TODO(Unknown): Maybe tweak these values
    final compressedData = await FlutterImageCompress.compressWithList(
      data,
      minHeight: 200,
      minWidth: 200,
      quality: 60,
      format: CompressFormat.png,
    );

    final hash = (await Sha1().hash(compressedData)).bytes;
    final hashhex = HEX.encode(hash);
    final avatarPath = await saveAvatarInCache(compressedData, hashhex, jid, oldPath);
    
    return PickedAvatar(avatarPath, hashhex);
  }

  return null;
}

/// Turn [text] into a text that can be used with the AvatarWrapper's alt.
/// [text] must be non-empty.
String avatarAltText(String text) {
  assert(text.isNotEmpty, 'Text for avatar alt must be non-empty');

  if (text.length == 1) return text[0].toUpperCase();

  return (text[0] + text[1]).toUpperCase();
}
