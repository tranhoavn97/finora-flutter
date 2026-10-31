import '../../core/widgets/finora_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/bank_launcher_helper.dart';
import '../../core/utils/vietqr_parser.dart';
import '../../core/theme/finora_tokens.dart';
import '../../data/models/vietqr_data.dart';

class BankAppSelectorSheet extends StatefulWidget {
  final VietQrData qrData;
  final double amount;
  final String memo;
  final String? preferredBankBin;
  final VoidCallback? onCancelTransaction;
  final Future<void> Function(BankInfo bank)? onBankSelected;
  const BankAppSelectorSheet(
      {super.key,
      required this.qrData,
      required this.amount,
      required this.memo,
      this.preferredBankBin,
      this.onCancelTransaction,
      this.onBankSelected});
  @override
  State<BankAppSelectorSheet> createState() => _BankAppSelectorSheetState();
}

class _BankAppSelectorSheetState extends State<BankAppSelectorSheet> {
  bool _opening = false;
  Future<void> _open(BankInfo bank) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (widget.onBankSelected != null) {
        await widget.onBankSelected!(bank);
      }
      if (!mounted) return;
      await BankLauncherHelper.launchBankAppDirect(
        context: context,
        bank: bank,
        data: widget.qrData,
        amount: widget.amount,
        memo: widget.memo,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _copy(String title, String value) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 12)),
      subtitle: Text(value.isEmpty ? 'Không có' : value,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: IconButton(
          tooltip: 'Sao chép $title',
          icon: const Icon(Icons.copy_rounded, size: 19),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (mounted)
              FinoraNotice.of(context)
                  .showSnackBar(SnackBar(content: Text('Đã sao chép $title')));
          }));
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final banks = <BankInfo>[
      VietQrParser.supportedBanks['970422']!,
      VietQrParser.supportedBanks['970407']!,
    ];
    final preferred = VietQrParser.findBank(widget.preferredBankBin);
    if (preferred != null) {
      banks.removeWhere((b) => b.bin == preferred.bin);
      banks.insert(0, preferred);
    }
    return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .88),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
              color: FinoraTokens.surface(dark),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(children: [
                  const Expanded(
                      child: Text('Mở ngân hàng',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded))
                ]),
                const Text(
                    'Bản nháp đang lưu trên máy. Mở ngân hàng không đồng nghĩa đã thanh toán.',
                    style: TextStyle(fontSize: 12, height: 1.5)),
                const SizedBox(height: 16),
                for (final bank in banks)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                          onPressed: _opening ? null : () => _open(bank),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              shape: const StadiumBorder()),
                          child: Row(children: [
                            Image.asset(bank.logo,
                                width: 32,
                                height: 32,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.account_balance_rounded)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Mở ${bank.name}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const Text(
                                      'Tạo giao dịch mẫu & điền sẵn STK, số tiền, nội dung qua VietQR',
                                      style: TextStyle(fontSize: 11),
                                      maxLines: 2)
                                ])),
                            const Icon(Icons.open_in_new_rounded, size: 18)
                          ]))),
                const Divider(),
                Text('Ngân hàng nhận: ${widget.qrData.bankName}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (widget.qrData.accountName != null)
                  Text('Tên từ mã QR: ${widget.qrData.accountName}'),
                _copy('Số tài khoản', widget.qrData.accountNumber),
                _copy('Số tiền', widget.amount.toInt().toString()),
                _copy('Nội dung', widget.memo),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại · Xác nhận đã thanh toán')),
              ])),
        ));
  }
}
