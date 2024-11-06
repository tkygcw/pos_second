import '../../object/table.dart';

class CartDialogFunction {
  List<PosTable> checkTable(List<PosTable> tableList, List<PosTable> cartSelectedTableList){
    // Step 1: Filter tables with status == 1
    List<PosTable> inUseTables = _getInUseTables(tableList);

    // Step 2: Mark tables in cartSelectedTableList that are also in inUseTables, and select their groups
    bool anyTableIncluded = _markSelectedTablesAndGroups(inUseTables, cartSelectedTableList, tableList);

    // Step 3: If no table from cartSelectedTableList is in inUseTables, mark only those in cartSelectedTableList as selected
    if (!anyTableIncluded) {
      _selectOnlyCartTables(tableList, cartSelectedTableList);
    }

    return tableList;
  }

  // Helper function to mark only tables in cartSelectedTableList as selected if none are in inUseTables
  void _selectOnlyCartTables(List<PosTable> tableList, List<PosTable> cartSelectedTableList) {
    for (var table in tableList) {
      for (var cartTable in cartSelectedTableList) {
        if (table.table_sqlite_id == cartTable.table_sqlite_id) {
          table.isSelected = true;
        }
      }
    }
  }

  // Helper function to mark all tables in the same group as selected
  void _selectTablesInGroup(String? groupId, List<PosTable> tableList) {
    for (var table in tableList) {
      if (table.group == groupId) {
        table.isSelected = true;
      }
    }
  }

  // Helper function to mark tables in cartSelectedTableList if they're in inUseTables and select their groups
  bool _markSelectedTablesAndGroups(List<PosTable> inUseTables, List<PosTable> cartSelectedTableList, List<PosTable> tableList) {
    bool anyTableIncluded = false;

    for (var cartTable in cartSelectedTableList) {
      for (var table in inUseTables) {
        if (table.table_sqlite_id == cartTable.table_sqlite_id) {
          anyTableIncluded = true;
          table.isSelected = true;

          // Mark all tables in the same group as selected
          _selectTablesInGroup(table.group, tableList);
        }
      }
    }

    return anyTableIncluded;
  }

  // Helper function to filter tables with status == 1
  List<PosTable> _getInUseTables(List<PosTable> tableList) {
    return tableList.where((table) => table.status == 1).toList();
  }
}