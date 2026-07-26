import 'package:image_picker/image_picker.dart';

enum SocialMediaSource { camera, gallery }

enum SocialMediaKind { image, video }

class SocialPickedMedia {
  const SocialPickedMedia({
    required this.path,
    required this.name,
    required this.kind,
    this.isAsset = false,
  });

  final String path;
  final String name;
  final SocialMediaKind kind;
  final bool isAsset;
}

abstract class SocialMediaPicker {
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source);

  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10});

  Future<SocialPickedMedia?> pickImage(SocialMediaSource source);

  Future<List<SocialPickedMedia>> recoverInterruptedSelection();
}

class NativeSocialMediaPicker implements SocialMediaPicker {
  NativeSocialMediaPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<SocialPickedMedia?> pickReel(SocialMediaSource source) async {
    final file = await _picker.pickVideo(
      source: source == SocialMediaSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return file == null
        ? null
        : SocialPickedMedia(
            path: file.path,
            name: file.name,
            kind: SocialMediaKind.video,
          );
  }

  @override
  Future<List<SocialPickedMedia>> pickCarousel({int limit = 10}) async {
    final files = await _picker.pickMultiImage(limit: limit);
    return files
        .map(
          (file) => SocialPickedMedia(
            path: file.path,
            name: file.name,
            kind: SocialMediaKind.image,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SocialPickedMedia?> pickImage(SocialMediaSource source) async {
    final file = await _picker.pickImage(
      source: source == SocialMediaSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      requestFullMetadata: false,
    );
    return file == null
        ? null
        : SocialPickedMedia(
            path: file.path,
            name: file.name,
            kind: SocialMediaKind.image,
          );
  }

  @override
  Future<List<SocialPickedMedia>> recoverInterruptedSelection() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null) {
      return const <SocialPickedMedia>[];
    }
    return response.files!
        .map(
          (file) => SocialPickedMedia(
            path: file.path,
            name: file.name,
            kind: SocialMediaKind.image,
          ),
        )
        .toList(growable: false);
  }
}
