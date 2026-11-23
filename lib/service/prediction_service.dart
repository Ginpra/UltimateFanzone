import '../model/prediction.dart';
import 'local_list_store.dart';

/// Tebakan skor (Hive lewat LocalListStore). Satu tebakan per laga.
class PredictionService {
  final LocalListStore _store = LocalListStore('predictions_v1');

  Future<List<Prediction>> loadAll() async {
    final raw = await _store.load();
    return raw.map(Prediction.fromJson).toList();
  }

  /// Simpan tebakan; tebakan lama untuk laga yang sama diganti.
  Future<void> save(Prediction prediction) async {
    final all = await loadAll();
    all.removeWhere((p) => p.matchId == prediction.matchId);
    all.add(prediction);
    await _store.save(all.map((p) => p.toJson()).toList());
  }
}
