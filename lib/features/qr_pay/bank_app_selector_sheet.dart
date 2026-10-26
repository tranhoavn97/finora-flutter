import 'package:flutter/material.dart';
import '../../core/utils/bank_launcher_helper.dart';
import '../../core/utils/vietqr_parser.dart';
import '../../data/models/vietqr_data.dart';

/// Bottom sheet displaying banking apps for App-to-App payment
class BankAppSelectorSheet extends StatelessWidget {
  final VietQrData qrData;
  final double amount;
  final String memo;
  final String? preferredBankBin;
  final VoidCallback? onCancelTransaction;

  const BankAppSelectorSheet({
    super.key,
    required this.qrData,
    required this.amount,
    required this.memo,
    this.preferredBankBin,
    this.onCancelTransaction,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Identify recommended bank
    final recommendedBank = VietQrParser.findBank(preferredBankBin) ??
        VietQrParser.findBank(qrData.bankBin) ??
        VietQrParser.supportedBanks['970436']!; // Default VCB

    // 2. Other popular banks & wallets
    final allBanks = <BankInfo>[
      ...VietQrParser.supportedBanks.values,
      ...VietQrParser.popularWallets,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã ghi sổ vào Finora!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chọn App Ngân hàng để thanh toán',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Summary Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chuyển đến: ${qrData.bankShortName} • ${qrData.accountNumber}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        BankLauncherHelper.copyAccountNumber(qrData.accountNumber);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã chép số tài khoản vào bộ nhớ tạm!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'Chép STK',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recommended Bank Action Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await BankLauncherHelper.launchBankApp(
                        context: context,
                        bank: recommendedBank,
                        data: qrData,
                        customAmount: amount,
                        customMemo: memo,
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        recommendedBank.logo,
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 38,
                          height: 38,
                          color: Colors.white24,
                          child: const Icon(Icons.account_balance, color: Colors.white),
                        ),
                      ),
                    ),
                    title: Text(
                      'Mở ${recommendedBank.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(
                      'Ứng dụng đề xuất theo ví nguồn',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Other Banks Grid Header
              Text(
                'HOẶC CHỌN ỨNG DỤNG KHÁC',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 10),

              // Horizontal bank list
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allBanks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final b = allBanks[i];
                    return InkWell(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await BankLauncherHelper.launchBankApp(
                          context: context,
                          bank: b,
                          data: qrData,
                          customAmount: amount,
                          customMemo: memo,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 68,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                b.logo,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance,
                                  size: 24,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.shortName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Undo Cancel action
              if (onCancelTransaction != null)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancelTransaction!();
                    },
                    icon: const Icon(Icons.undo_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: const Text(
                      'Huỷ ghi sổ (Nếu bạn không thanh toán)',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
