import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/blurhash.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/download.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/filenotfound.dart';
import 'package:moxxyv2/ui/widgets/chat/gradient.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:open_file/open_file.dart';

class ImageBaseChatWidget extends StatelessWidget {

  const ImageBaseChatWidget(
    this.path,
    this.radius,
    this.child,
    this.bottom,
    {
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final String? path;
  final BorderRadius radius;
  final Widget child;
  final Widget? extra;
  final MessageBubbleBottom bottom;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkResponse(
        onTap: () {
          if (path != null) {
            OpenFile.open(path);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: child,
            ),
            BottomGradient(radius),
            ...extra != null ? [ extra! ] : [],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3, right: 6),
                child: bottom,
              ),
            ) 
          ],
        ),
      ),
    );
  }
}

class ImageChatWidget extends StatelessWidget {

  const ImageChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    {
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final BorderRadius radius;
  final double maxWidth;
  final Widget? extra;

  Widget _buildNonDownloaded() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);
      return BlurhashChatWidget(
        width: thumbnailSize.width.toInt(),
        height: thumbnailSize.height.toInt(),
        borderRadius: radius,
        thumbnailData: message.thumbnailData!,
        child: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    }

    return FileChatWidget(
      message,
      extra: ElevatedButton(
        onPressed: () => requestMediaDownload(message),
        child: const Text('Download'),
      ),
    );
  }

  Widget _buildDownloading() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);
      return BlurhashChatWidget(
        width: thumbnailSize.width.toInt(),
        height: thumbnailSize.height.toInt(),
        borderRadius: radius,
        thumbnailData: message.thumbnailData!,
        child: DownloadProgress(id: message.id),
      );
    }

    return FileChatWidget(message);
  }

  Widget _buildImage() {
    final thumbnailSize = getThumbnailSize(message, maxWidth);

    return FutureBuilder<Uint8List>(
      future: GetIt.I.get<ThumbnailCacheService>().getImageThumbnail(message.mediaUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
            );
          } else if (message.thumbnailData != null) {
            return BlurhashChatWidget(
              width: thumbnailSize.width.toInt(),
              height: thumbnailSize.height.toInt(),
              borderRadius: radius,
              thumbnailData: message.thumbnailData!,
              child: const FileNotFound(),
            );
          } else {
            return FileChatWidget(
              message,
              extra: const FileNotFound(),
            );
          }
        } else {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
  
  Widget _innerBuild() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildImage();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return ImageBaseChatWidget(
      message.mediaUrl,
      radius,
      _innerBuild(),
      MessageBubbleBottom(message),
    );
  }
}
