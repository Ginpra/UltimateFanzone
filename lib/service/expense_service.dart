import '../model/expense.dart';
import 'local_list_store.dart';

/// Pengeluaran Away Day (Hive lewat LocalListStore).
class ExpenseService {
  final LocalListStore _store = LocalListStore('expenses_v1');

  Future<List<Expense>> loadAll() async {
    final raw = await _store.load();
    return raw.map(Expense.fromJson).toList();
  }

  Future<void> add(Expense expense) async {
    final all = await loadAll();
    all.add(expense);
    await _store.save(all.map((e) => e.toJson()).toList());
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _store.save(all.map((e) => e.toJson()).toList());
  }
}
