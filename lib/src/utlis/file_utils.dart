import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart';
Future<ui.Image> imageFromFile(File file) async {
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

class FileUtils {
  static String documentsDir = 'documents';

// configured android:authorities in AndroidManifest (https://developer.android.com/reference/android/support/v4/content/FileProvider)
  static String authority = 'YOUR_AUTHORITY.provider';
  static String hiddenPrefix = ".";

  static String tag = 'FileUtils';
  static bool debug = false; //

  static Comparator<File> get sComparator => (f1, f2) {
        return basename(f1.path).toLowerCase().compareTo(basename(f2.path).toLowerCase());
      };

  static List<String> imageSupport = [
    '.bmp',
    '.dib',
    '.jpe',
    '.jfif',
    '.tiff',
    '.png',
    '.jpg',
    '.jpeg',
    '.tif',
  ];

  static String? getExtension(String? uri, {bool hasDot = true}) {
    if (uri == null) {
      return null;
    }

    int dot = uri.lastIndexOf('.');
    String result = '';
    if (dot >= 0) {
      result = uri.substring(dot);
    } else {
// No extension.
      result = '';
    }

    if (hasDot) {
      return result;
    } else {
      return result.replaceAll('.', '');
    }
  }

  static bool isLocal(String? url) {
    return url != null && !url.startsWith('http://') && !url.startsWith('https://');
  }

  static bool isMediaUri(Uri uri) {
    return 'media' == uri.authority.toLowerCase();
  }

  static String? getPathWithoutFileName(File? file) {
    if (file != null) {
      String filename = basename(file.path);
      String filepath = file.absolute.path;

// Construct path without file name.
      String pathWithoutName = filepath.substring(0, filepath.length - filename.length);
      if (pathWithoutName.endsWith('/')) {
        pathWithoutName = pathWithoutName.substring(0, pathWithoutName.length - 1);
      }
      return pathWithoutName;
    }

    return '';
  }

  static String getFileNameFromPath(String path, {bool containExt = true}) {
    if (containExt) {
      return basename(path);
    }

    String? ext = getExtension(path);
    String fileName = '';
    if (ext != null) {
      fileName = basename(path).replaceAll(ext, '');
    }
    return fileName;
  }

  // static String? getMimeType(File file) {
  //   return lookupMimeType(file.path);
  // }

  static bool isLocalStorageDocument(Uri uri) {
    return authority == uri.authority;
  }

  static bool isExternalStorageDocument(Uri uri) {
    return false;
  }

  // /// tao ra file có tên duy nhất (lấy theo thời gian thực)
  // static File? generateFileName(String name, File file) {
  //   String? path = getPathWithoutFileName(file);
  //
  //   if (path == null) return null;
  //
  //   String? extension = getExtension(file.path);
  //
  //   String suffixes = const Uuid().v1();
  //
  //   String fileName = join(path, suffixes, extension);
  //
  //   return file.renameSync(fileName);
  // }

  /// save file từ internet xuống bộ nhớ local
  static void saveFileFromUri(Uri uri, String destinationPath) {}

  /// [image] là hình ảnh muốn nén (giảm chất lượng)
  /// [percentReduce] % bạn muốn giảm. Giả sử nếu  1 ảnh 10M, percentReduce = 50
  /// -> file có kích thước 5M
// static Future<File> compressImage(File file, int percentReduce) async {
//   assert(percentReduce > 0 && percentReduce < 100);
//
//   if (!file.existsSync()) {
//     throw Exception('File not exist');
//   }
//
//   if (!file.isImageTypeSupported()) {
//     throw Exception('File is not Image or Image not support');
//   }
//
//   File compressedFile = await FlutterNativeImage.compressImage(file.path,
//       percentage: percentReduce);
//
//   return compressedFile;
// }

// static Future<File> compressVideo(File file,
//     {bool deleteOrigin = false,
//       VideoQuality videoQuality = VideoQuality.MediumQuality,
//       bool includeAudio = true}) async {
//   if (!file.existsSync()) {
//     throw Exception('File not exist');
//   }
//
//   if (!file.isVideoTypeSupported()) {
//     throw Exception('File is not Video or Video not support');
//   }
//
//   final MediaInfo? info = await VideoCompress.compressVideo(
//     file.path,
//     quality: videoQuality,
//     deleteOrigin: false,
//     includeAudio: true,
//   );
//
//   if (info?.file == null) {
//     throw Exception('Err from lib VideoCompress ');
//   }
//
//   return File(info?.file?.path ?? '');
// }

  static int getFileSize(String path) {
    return File(path ?? '').getSizeByte();
  }

  static bool checkFileSize(File file, int maxSizeKb) {
    int size = file.getSizeKB();
    bool check = size <= maxSizeKb;
    return check;
  }

  static bool checkAllowType(File file, List<String> list) {
    String extension = FileUtils.getExtension(file.path) ?? '';
    if (extension.isEmpty) return false;
    bool check = list.contains(extension);
    return check;
  }
}

enum FileCategory { image, video, imageAndVideo, attack, none }

class FileSupport {
  static List<String> imageTypeSupport = ['JPG', 'JPEG'];

  static List<String> videoTypeSupport = ['mp4', 'mov'];

  static List<String> videoAndImageTypeSupport = [...imageTypeSupport, ...videoTypeSupport];

  static List<String> otherTypeSupport = ['pdf', 'doc', 'docx'];
}

extension FileCategoryExtensionSupport on FileCategory {
// nhung loai duoi file support;
  List<String> getExtensionSupport() {
    switch (this) {
      case FileCategory.image:
        return FileSupport.imageTypeSupport;
      case FileCategory.video:
        return FileSupport.videoTypeSupport;
      case FileCategory.imageAndVideo:
        return FileSupport.videoAndImageTypeSupport;
      case FileCategory.attack:
        return FileSupport.otherTypeSupport;
      case FileCategory.none:
// TODO: Handle this case.
        return [];
    }
  }
}

extension FileExtension on File {
  ///trả về loại File bằng cách nhận biết đuôi url.
  FileCategory get getFileCategoryFromUrlExtension => _getURLExtension();

  FileCategory _getURLExtension() {
    for (var element in FileSupport.imageTypeSupport) {
      if (_regexFileExtension(path, element)) return FileCategory.image;
    }

    for (var element in FileSupport.videoTypeSupport) {
      if (_regexFileExtension(path, element)) return FileCategory.video;
    }

    for (var element in FileSupport.otherTypeSupport) {
      if (_regexFileExtension(path, element)) return FileCategory.attack;
    }

    return FileCategory.none;
  }

  bool isImageTypeSupported() => _getURLExtension() == FileCategory.image;

  bool isVideoTypeSupported() => _getURLExtension() == FileCategory.video;

  int getSizeKB() {
    return readAsBytesSync().length ~/ 1024;
  }

  double getSizeMB() {
    return getSizeKB() / 1024;
  }

  int getSizeByte() {
    return readAsBytesSync().length;
  }

  bool _regexFileExtension(String content, String fileExtension) {
    List<String> array = fileExtension.split('');

    String fileExtensionToArray = array.fold<String>('', (prev, character) => '$prev[$character]');

    RegExp exp = RegExp(r'.*[\.]' '$fileExtensionToArray' r"$", multiLine: false, caseSensitive: false);

    return exp.hasMatch(content);
  }
}
