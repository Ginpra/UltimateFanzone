/// Tempat menyimpan alamat gambar logo klub yang dikirim API, dicari lewat nama klub.
/// Diisi saat data jadwal, klasemen, top skor, atau daftar klub dimuat, jadi
/// widget mana pun cukup memberi nama klub tanpa membawa URL.
class CrestRegistry {
  static final Map<String, String> _urls = {};

  static void register(String name, String? url) {
    if (url == null || url.isEmpty) return;
    _urls[name] = url;
  }

  static String? urlFor(String name) => _urls[name];
}
