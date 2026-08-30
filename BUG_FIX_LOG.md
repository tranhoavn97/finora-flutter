# FINORA FLUTTER - BUG FIX LOG

| Screen/Feature | Bug/Issue | Root Cause | Solution/Fix Applied |
| :--- | :--- | :--- | :--- |
| **AuthScreen** | Không có validation rỗng, exception chưa bắt đầy đủ gây sập app | Thiếu `trim()` và kiểm tra chuỗi rỗng trước khi push auth | Thêm logic kiểm tra empty, show SnackBar, cập nhật Loading UI `_isLoading` kết hợp `try-catch` an toàn. |
| **AddTransactionPage** | User có thể bấm nhiều lần liên tiếp khi mạng chậm | Thiếu trạng thái `_isSaving` | Bổ sung `_isSaving` state, vô hiệu hoá button `onPressed` khi đang xử lý, và thêm block `try-catch-finally` |
| **AddTransactionPage** | Lỗi memory leak do `Navigator.pop` sau async request mà widget đã bị huỷ | Không có check `mounted` sau `await` | Thêm check `if (mounted)` trước mọi thao tác Navigator hoặc `setState`. |
| **AddWalletPage** | Form Submit thiếu debounce và exception handling | Giống Transaction, xử lý call DB không có await/try | Sửa hàm thành `async`, thêm `_isSaving`, try-catch cho logic `context.read<WalletProvider>().addWallet()`. |
| **AddBudgetPage** | Lỗi double-submit khi thêm ngân sách mới | Gọi provider synchronous thiếu loading feedback | Thêm `_isSaving`, xử lý try-catch, loading indicator trên nút. |
| **AddCategoryPage** | Có thể tạo tên trống, double-submit | Thiếu return early khi empty, thiếu try-catch. | Cập nhật `_submit` xử lý `if (name.isEmpty) return`, thêm try-catch, và loading UI. |
| **AddAssetPage** | Không thể xử lý parse dấu phẩy (,) thành chấm (.) gây lỗi crash FormatException | `double.parse` hoặc `int.parse` không bao bọc try-catch, format string bị lỗi | Bổ sung `replaceAll(',', '.')` và `tryParse` mặc định fallback = 0/1. Thêm try-catch form. |
| **AddGoalPage** | Có thể bị crash do exception bất ngờ khi submit | Gọi Provider sync nhưng server-side lỗi hoặc mất mạng | Chuyển logic `_submit` thành async/await, try-catch và `_isSaving` loading indicator. |
| **LoanScreen (Repay & Add)** | Cùng vấn đề về double-submit và try-catch | Exception Firebase có thể làm crash Dialog | Bổ sung state `_isSaving`, try-catch, check mounted. |
| **TransactionProvider** | Tình trạng query lại `transactions` (get O(N)) mỗi lần update wallet | Logic listen `watchWallets` gọi getTransactions trực tiếp `await _txRepo.getTransactions(userId)` | Viết lại caching memory: _all, _rawWallets, sử dụng docChanges trong `watchTransactions` từ Repo. |
| **TransactionRepository** | Hiệu suất kém khi transaction lớn do serialize toàn bộ map | `map(d.data())` trên toàn bộ snapshot docs cho mỗi thay đổi | Thay bằng `docChanges`, duy trì `Map<String, TransactionModel> cache` giúp giảm O(N) parsing xuống O(1) tuỳ thay đổi. |

---
## Các vấn đề khác đã khắc phục:
- Chuẩn hoá toàn bộ các UI nút bấm có trạng thái `Loading`.
- Fix memory leaks do context navigation sau khi await Firebase call.
- Bắt tất cả Firebase Error để chuyển thành user-friendly Snackbar thay vì crash đỏ màn hình.
