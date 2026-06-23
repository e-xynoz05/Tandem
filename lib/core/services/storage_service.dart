import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing file uploads to Supabase Storage.
class StorageService {
  StorageService(this._sb);

  final SupabaseService _sb;
  SupabaseClient get _client => _sb.client;

  /// Uploads a profile image to the 'avatars' bucket.
  /// 
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final ext = path.extension(imageFile.path);
      final fileName = 'profiles/$uid$ext';
      
      // Upload file to Supabase
      await _client.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: FileOptions(
          contentType: 'image/${ext.replaceFirst('.', '')}',
          upsert: true,
        ),
      );
      
      // Get public URL
      final url = _client.storage.from('avatars').getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Deletes a file in the 'avatars' bucket by its URL/Path.
  Future<void> deleteFile(String url) async {
    try {
      // Extract path from URL if needed, or assume path is provided
      // For simplicity, we assume the user provides the storage path or we parse it
      final uri = Uri.parse(url);
      final pathParts = uri.pathSegments;
      if (pathParts.length > 2) {
        final storagePath = pathParts.sublist(pathParts.indexOf('avatars') + 1).join('/');
        await _client.storage.from('avatars').remove([storagePath]);
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}

/// Global provider for [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return StorageService(sb);
});
