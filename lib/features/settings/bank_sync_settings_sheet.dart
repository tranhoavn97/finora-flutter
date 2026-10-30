import '../../core/widgets/finora_notice.dart';
import 'package:flutter/material.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';
import '../../core/utils/formatters.dart';

class BankSyncSettingsSheet extends StatefulWidget {
  final String userId;
  const BankSyncSettingsSheet({super.key, required this.userId});
  static Future<void> show(BuildContext context,
      {required String userId}) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => BankSyncSettingsSheet(userId: userId));
  }

  @override
  State<BankSyncSettingsSheet> createState() => _BankSyncSettingsSheetState();
}

class _BankSyncSettingsSheetState extends State<BankSyncSettingsSheet>
    with WidgetsBindingObserver {
  final _service = BankSyncService();
  bool _granted = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _service.isPermissionGranted();
    await _service.checkPendingNotifications();
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: AnimatedBuilder(
            animation: _service,
            builder: (context, _) => ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Nhận diện ngân hàng',
                              style: Theme.of(context).textTheme.titleLarge)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ]),
                    const SizedBox(height: 12),
                    Text(
                        !_service.supported
                            ? 'Chỉ hỗ trợ đọc thông báo trên Android'
                            : !_granted
                                ? 'Chưa cấp quyền truy cập thông báo'
                                : _service.connected
                                    ? 'Đã kết nối dịch vụ thông báo'
                                    : 'Đã cấp quyền • Dịch vụ chưa kết nối',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                        'FINORA đọc thông báo biến động số dư từ app ngân hàng và ứng dụng SMS. Giao dịch chỉ được ghi vào sổ sau khi bạn xác nhận. Không truy cập lịch sử tài khoản ngân hàng.'),
                    if (_service.supported) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () async {
                            if (!_granted) {
                              await _service.requestPermission();
                            } else {
                              await _service.reconnect();
                              await _service.requestPostNotifications();
                            }
                            await _refresh();
                          },
                          child: Text(!_granted
                              ? 'Cấp quyền đọc thông báo'
                              : 'Kiểm tra kết nối')),
                      TextButton(
                          onPressed: _service.openAppInfo,
                          child: const Text(
                              'Mở thông tin ứng dụng / Cài đặt bị hạn chế')),
                    ],
                    if (_service.lastReceivedAt != null)
                      Text(
                          'Thông báo gần nhất: ${_service.lastReceivedAt!.toLocal()}'),
                    if (_service.error != null)
                      Text(_service.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    const Divider(height: 32),
                    Text('Chờ ghi vào sổ (${_service.pending.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (_service.pending.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                              'Chưa có giao dịch chờ xử lý. Khi ngân hàng gửi thông báo có số tiền, giao dịch nhận diện được sẽ xuất hiện tại đây.')),
                    ..._service.pending.map((tx) => Card(
                            child: ListTile(
                          title: Text(
                              '${tx.bankName} • ${tx.isIncome ? '+' : '−'}${Formatters.formatCurrency(tx.amount)}'),
                          subtitle: Text(tx.note,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => BankTransactionPromptSheet.show(context,
                              transaction: tx, userId: widget.userId),
                          trailing: IconButton(
                              tooltip: 'Bỏ qua thông báo',
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                final discard = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                            title: const Text(
                                                'Bỏ qua thông báo này?'),
                                            content: const Text(
                                                'Thông báo này sẽ không được ghi vào sổ.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Giữ lại')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Bỏ qua'))
                                            ]));
                                if (discard == true) {
                                  try {
                                    await _service.acknowledge(tx.rawId);
                                  } catch (_) {
                                    if (context.mounted)
                                      FinoraNotice.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Chưa bỏ qua được. Hãy thử lại.')));
                                  }
                                }
                              }),
                        ))),
                    if (_service.unrecognizedCount > 0)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                              '${_service.unrecognizedCount} thông báo chưa xác định đủ số tiền và chiều thu/chi. Nội dung gốc vẫn được giữ trên thiết bị; bạn có thể ghi giao dịch thủ công.')),
                    ..._service.unrecognized.entries
                        .map((event) => ExpansionTile(
                              title: Text(event.value.title.isEmpty
                                  ? 'Thông báo chưa nhận diện'
                                  : event.value.title),
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SelectableText(event.value.text))
                              ],
                            )),
                    const Divider(height: 32),
                    const Text(
                        'Phân tích thông báo trên thiết bị, bỏ qua OTP và mật khẩu. Giao dịch bạn xác nhận được đồng bộ vào tài khoản FINORA.'),
                  ],
                )),
      ));
}
