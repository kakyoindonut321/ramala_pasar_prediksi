import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ramala/core/config/env.dart';

class CloudinaryService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  /// Kompres lalu unggah (unsigned preset). Mengembalikan secure_url.
  Future<String> uploadAvatar(String path) async {
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
    final res = await _dio.post(
      'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloud}/image/upload',
      data: FormData.fromMap({
        'upload_preset': Env.cloudinaryPreset,
        'file': MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
      }),
    );
    return res.data['secure_url'] as String;
  }
}
