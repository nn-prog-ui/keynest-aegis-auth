import 'import_item.dart';
import 'import_source.dart';

abstract interface class ImportParser {
  ImportSource get source;

  Future<List<ImportItem>> parse();
}
