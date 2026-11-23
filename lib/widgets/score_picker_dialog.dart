import 'package:flutter/material.dart';

/// Dialog memilih skor tebakan dengan tombol minus dan plus.
///
/// Mengembalikan `[skorTuanRumah, skorTamu]` lewat `Navigator.pop`,
/// atau null bila dibatalkan.
class ScorePickerDialog extends StatefulWidget {
  const ScorePickerDialog({
    super.key,
    required this.homeName,
    required this.awayName,
    this.initialHome = 0,
    this.initialAway = 0,
  });

  final String homeName;
  final String awayName;
  final int initialHome;
  final int initialAway;

  @override
  State<ScorePickerDialog> createState() => _ScorePickerDialogState();
}

class _ScorePickerDialogState extends State<ScorePickerDialog> {
  late int _home = widget.initialHome;
  late int _away = widget.initialAway;

  Widget _counter(String name, int value, void Function(int) onChanged) {
    return Column(
      children: [
        Text(name, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < 20 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tebak skor'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _counter(
              widget.homeName,
              _home,
              (v) => setState(() => _home = v),
            ),
          ),
          Expanded(
            child: _counter(
              widget.awayName,
              _away,
              (v) => setState(() => _away = v),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, [_home, _away]),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
