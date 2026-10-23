import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MarketImageService {
  static const _cloud = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _preset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  /// Kompres JPEG lalu unggah. Melempar FormatException('image') bila tidak valid.
  Future<String> upload(String path) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 512,
      minHeight: 512,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (bytes == null || bytes.length > 3 * 1024 * 1024) {
      throw const FormatException('image');
    }
    final r = await Dio().post(
      'https://api.cloudinary.com/v1_1/$_cloud/image/upload',
      data: FormData.fromMap({
        'upload_preset': _preset,
        'file': MultipartFile.fromBytes(bytes, filename: 'market.jpg'),
      }),
    );
    final url = r.data['secure_url'] as String;
    if (!url.startsWith('https://res.cloudinary.com/')) {
      throw const FormatException('image');
    }
    return url;
  }
}
