# Membuat lib/core/secrets.dart dari env.json (sekali saja).
# Jalankan dari folder projek:  .\siapkan_kunci.ps1
$j = Get-Content -Raw env.json | ConvertFrom-Json
function Ambil($nama) { if ($j.PSObject.Properties[$nama]) { $j.$nama } else { '' } }
$isi = @"
// Dibuat otomatis dari env.json. Jangan di-commit (sudah di .gitignore).
class Secrets {
  static const String footballApiKey = r'$(Ambil 'FOOTBALL_API_KEY')';
  static const String geminiApiKey = r'$(Ambil 'GEMINI_API_KEY')';
  static const String geminiModel = r'$(Ambil 'GEMINI_MODEL')';
}
"@
Set-Content -Path lib/core/secrets.dart -Value $isi -Encoding UTF8
Write-Host "Selesai: lib/core/secrets.dart dibuat."
