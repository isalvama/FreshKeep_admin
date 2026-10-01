import 'receipts_list_query.dart';

/// The last receipts list URL visited this session, so "← Back to receipts"
/// on a receipt's page returns to the same range, creator and page. In memory
/// only (a get_it singleton): a reload starts from the default again.
class ReceiptsListLocation {
  String _value = receiptsListLocation(kDefaultReceiptsListQuery);

  String get value => _value;

  /// Records a list URL. Anything that isn't the receipts list is ignored.
  void remember(String location) {
    if (Uri.parse(location).path == kReceiptsPath) _value = location;
  }
}
