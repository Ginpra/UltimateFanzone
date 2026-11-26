import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_tokens.dart';
import '../core/format.dart';
import '../model/expense.dart';
import '../service/expense_service.dart';
import '../service/settings_service.dart';
import '../widgets/empty_state.dart';
import 'expense_form_page.dart';

/// Away Day: catat pengeluaran tandang dan pantau anggaran.
/// Modul: II, III, IV, VI (Hive untuk pengeluaran, SharedPreferences untuk anggaran).
class AwayDayPage extends StatefulWidget {
  const AwayDayPage({super.key});

  @override
  State<AwayDayPage> createState() => _AwayDayPageState();
}

class _AwayDayPageState extends State<AwayDayPage> {
  final _expenseService = ExpenseService();
  final _settings = SettingsService();

  List<Expense> _expenses = [];
  int _budget = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _expenseService.loadAll();
    final budget = await _settings.loadBudget();
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _budget = budget;
      _loading = false;
    });
  }

  int get _total => _expenses.fold(0, (sum, e) => sum + e.amount);

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
    );
    if (saved == true) await _load();
  }

  Future<void> _editBudget() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => _BudgetDialog(initialAmount: _budget),
    );
    if (amount == null) return;
    await _settings.saveBudget(amount);
    await _load();
  }

  Future<bool> _confirmDelete(Expense expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: Text('"${expense.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await _expenseService.delete(expense.id);
    if (!mounted) return true;
    setState(() => _expenses.removeWhere((e) => e.id == expense.id));
    return true;
  }

  Widget _summaryCard() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final over = _budget > 0 && _total > _budget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total pengeluaran'),
            Text(formatRupiah(_total), style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_budget > 0) ...[
              LinearProgressIndicator(
                value: (_total / _budget).clamp(0.0, 1.0),
                color: over ? scheme.error : null,
              ),
              const SizedBox(height: 8),
              Text(
                over
                    ? 'Melebihi anggaran ${formatRupiah(_total - _budget)}'
                    : 'Sisa ${formatRupiah(_budget - _total)} dari ${formatRupiah(_budget)}',
                style: TextStyle(color: over ? scheme.error : null),
              ),
            ] else
              const Text('Anggaran belum diatur.'),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _editBudget,
                child: Text(_budget > 0 ? 'Ubah anggaran' : 'Atur anggaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Away Day')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Pengeluaran'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _summaryCard(),
                if (_expenses.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada pengeluaran',
                    message: 'Tekan tombol Pengeluaran untuk mencatat.',
                  )
                else
                  for (final e in _expenses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(e),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Theme.of(context).colorScheme.error,
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(e.title),
                            subtitle: Text(
                              '${e.category} · ${formatDateTime(e.createdAt)}',
                            ),
                            trailing: Text(formatRupiah(e.amount)),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.initialAmount});

  final int initialAmount;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0 ? '${widget.initialAmount}' : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      int.tryParse(_controller.text.trim()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anggaran Away Day'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Anggaran (Rp)'),
          validator: (value) {
            final amount = int.tryParse(value?.trim() ?? '');
            if (amount == null || amount < 0) {
              return 'Masukkan angka anggaran';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
