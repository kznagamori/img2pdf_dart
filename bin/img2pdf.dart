import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final directory = Directory.current;
  final pdf = pw.Document();
  final imageQuality = 75;
  // 拡張子フィルター
  var imageExtensions = ['.jpg', '.jpeg', '.png'];

  // ディレクトリ内のファイルリスト
  var files = directory
      .listSync()
      .where((item) =>
          imageExtensions.contains(p.extension(item.path).toLowerCase()))
      .toList();

  // 数字でソート（ゼロサプレス対応）
  files.sort((a, b) {
    var nameA = int.parse(p.basenameWithoutExtension(a.path));
    var nameB = int.parse(p.basenameWithoutExtension(b.path));
    return nameA.compareTo(nameB);
  });
  for (var file in files) {
    var imageBytes = File(file.path).readAsBytesSync();
    var image = decodeImage(imageBytes);
    if (image != null) {
      // JPEG形式で圧縮
      var jpeg = encodeJpg(image, quality: imageQuality);
      // Uint8Listに変換
      var jpegBytes = Uint8List.fromList(jpeg);
      var page = pw.Page(
          pageFormat: PdfPageFormat(image.width.toDouble() * 72 / 300,
              image.height.toDouble() * 72 / 300),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(jpegBytes), fit: pw.BoxFit.cover),
            );
          });
      pdf.addPage(page);
    }
  }

  // カレントディレクトリ名をPDFファイル名として使用
  final outputFileName = '${p.basename(directory.path)}.pdf';
  final outputFile = File(p.join(directory.path, outputFileName));
  await outputFile.writeAsBytes(await pdf.save());
}
