/// Từ điển chỉ số tài chính chuẩn mực cho FINORA (Financial Metrics Dictionary)
/// Thiết lập quy tắc tính toán rõ ràng, tránh nhập nhằng giữa thu chi thực tế
/// và các dòng dịch chuyển thanh khoản nội bộ (chuyển ví, góp mục tiêu, mua tài sản, trả nợ).
library;

abstract final class FinancialMetrics {
  /// 1. Các loại giao dịch mang tính chất Thu nhập thực tế (Income)
  /// Làm tăng tổng tài sản ròng của cá nhân / gia đình.
  static const Set<String> incomeTypes = {
    'income',
  };

  /// 2. Các loại giao dịch mang tính chất Chi tiêu tiêu dùng thực tế (Expense)
  /// Làm giảm tổng tài sản ròng của cá nhân / gia đình.
  static const Set<String> expenseTypes = {
    'expense',
  };

  /// 3. Dịch chuyển thanh khoản nội bộ (Internal Transfers)
  /// Không làm thay đổi tài sản ròng, chỉ chuyển đổi hình thái tiền tệ giữa các ví hoặc quỹ.
  /// Tuyệt đối KHÔNG tính vào tổng chi tiêu sinh hoạt trên Báo cáo chi tiêu.
  static const Set<String> internalTransferTypes = {
    'transfer', // Chuyển tiền giữa 2 ví
    'saving', // Góp tiền vào mục tiêu tiết kiệm
    'investment', // Mua tài sản / đầu tư
    'asset_purchase', // Mua tài sản
  };

  /// 4. Các loại giao dịch liên quan đến Sổ nợ (Debts & Loans)
  static const Set<String> loanTypes = {
    'lending', // Cho người khác vay (giảm tiền mặt, tăng nợ phải thu)
    'borrowing', // Đi vay người khác (tăng tiền mặt, tăng nợ phải trả)
    'debt_repayment', // Trả nợ đã vay (giảm tiền mặt, giảm nợ phải trả)
    'loan_repayment_received', // Thu hồi nợ cho vay (tăng tiền mặt, giảm nợ phải thu)
    'credit_card_payment', // Thanh toán sao kê thẻ tín dụng (chuyển tiền từ thẻ ghi nợ/tiền mặt sang trả nợ thẻ)
  };

  /// Kiểm tra xem một loại giao dịch có phải là chi tiêu tiêu dùng hay không
  static bool isConsumerExpense(String type) => expenseTypes.contains(type);

  /// Kiểm tra xem một loại giao dịch có phải là thu nhập tiêu dùng hay không
  static bool isRealIncome(String type) => incomeTypes.contains(type);

  /// Kiểm tra xem một loại giao dịch có phải là dịch chuyển nội bộ hay không
  static bool isInternalTransfer(String type) =>
      internalTransferTypes.contains(type);

  /// Kiểm tra xem một loại giao dịch có liên quan đến sổ nợ hay không
  static bool isDebtOrLoan(String type) => loanTypes.contains(type);

  /// Tên gọi chuẩn tiếng Việt cho từng chỉ số
  static const String labelAvailableCash = 'Tiền có thể chi';
  static const String labelNetWorth = 'Tài sản ròng';
  static const String labelNetCashflow = 'Dòng tiền ròng';
  static const String labelTotalIncome = 'Tổng thu nhập';
  static const String labelTotalExpense = 'Tổng chi tiêu';
  static const String labelReceivableDebt = 'Cần thu hồi';
  static const String labelPayableDebt = 'Cần chi trả';
}
