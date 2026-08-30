# BÁO CÁO AUDIT TOÀN BỘ PROJECT FINORA FLUTTER

## 1. Chức năng hoạt động
- **Kiến trúc State Management:** Ứng dụng sử dụng `Provider` với `ChangeNotifier`, tổ chức hợp lý (ví dụ: `TransactionProvider`, `WalletProvider`, `BudgetProvider`).
- **Repositories & Firestore:** Các class Repository (`TransactionRepository`, `WalletRepository`, `BudgetRepository`) đã thiết lập `Stream` (như `watchTransactions`, `watchWallets`) để nhận dữ liệu realtime (Realtime Listeners). 
- **Authentication:** Đăng nhập qua Email/Password và Google Sign-In đã được kết nối với Firebase Auth. Repository thực hiện chức năng đồng bộ `Profile`.
- **Thao tác Dữ liệu (CRUD):** Các thao tác tạo, đọc, cập nhật, xoá (CRUD) cho Transactions, Wallets, Budgets đã được thiết lập qua Firestore. Chức năng cascade (xóa giao dịch liên đới xóa/cập nhật tài sản/khoản vay) đã được implement.
- **Offline Cache:** Mặc định của Firestore trên mobile đã hỗ trợ offline persistence, giúp thao tác đọc/ghi khi không có mạng vẫn diễn ra mượt mà và tự đồng bộ khi có mạng.
- **Memory Management (Cơ bản):** Các Provider đã có hàm `_cancel()` để huỷ `StreamSubscription`, Controller trong form cũng đã có `dispose()`.

## 2. Chức năng lỗi
- **Form validation:** Tại màn hình Auth (`auth_screen.dart`), việc kiểm tra (validation) trường email, mật khẩu trước khi gửi request chưa chặt chẽ (ví dụ: có thể gửi form rỗng).
- **Hardcode Database ID:** Ứng dụng đang hardcode `databaseId: 'ai-studio-2b22d4a0-9f50-4bbc-a8ed-f26d36b92339'` cho Firestore. Việc này hoạt động nhưng không linh hoạt, tuy nhiên theo yêu cầu không đổi Firebase thì sẽ giữ nguyên.
- **Tính toán số dư:** Hàm `computeWalletsWithBalances` đang tính toán lại toàn bộ số dư bằng cách duyệt qua TẤT CẢ các transaction. Nếu dữ liệu lớn, sẽ gây lag UI và chậm ứng dụng.

## 3. Chức năng chưa hoàn thiện
- **Empty States & Error States:** Cần kiểm tra kỹ các UI khi dữ liệu rỗng (chưa có giao dịch, chưa có ví) để đảm bảo không bị lỗi giao diện hoặc hiển thị kém thân thiện.
- **Xử lý Network Error:** Chưa có cơ chế retry tường minh khi bị rớt mạng ngay giữa chừng lúc thực thi thao tác (dù Firestore có auto-retry, UI cần thể hiện trạng thái kết nối).

## 4. Chức năng chỉ có UI
- Ứng dụng tương đối sạch sẽ, không có các placeholder `TODO`, `dummy` lộ liễu, hầu hết các button đều đã được gắn logic.

## 5. Chức năng thiếu backend
- **Notifications:** Có collection `notifications` được ghi dữ liệu (ví dụ: khi `ensureBudgets` chạy) nhưng chưa có Firebase Cloud Messaging (FCM) để push notification thực tế.

## 6. Firebase lỗi
- Khởi tạo Firebase `Firebase.initializeApp()` không có `options` (firebase_options.dart). Dù vẫn chạy được trên Android qua google-services.json, nhưng sẽ lỗi nếu build cho nền tảng khác (Web).

## 7. Realtime lỗi
- Không có lỗi nghiêm trọng về Realtime. Tuy nhiên, luồng stream `watchWallets` kết hợp với `getTransactions` có thể dẫn đến việc tính toán lại nhiều lần nếu một trong hai thay đổi. 

## 8. Crash tiềm ẩn
- **Type Casting:** Một số thao tác xử lý dữ liệu từ Firestore (đặc biệt các số nguyên/thực) có thể bị crash nếu Firestore trả về `int` thay vì `double`. Đã có hàm `coerce` xử lý nhưng cần đảm bảo tất cả đều bọc qua hàm này.
- Mất Context khi show SnackBar: Gọi `ScaffoldMessenger.of(context)` bên trong listener stream mà không kiểm tra cẩn thận có thể ném lỗi nếu widget đã bị huỷ trước đó (mặc dù đã check `mounted`).

## 9. Memory leak
- Các StreamSubscription đã được huỷ trong hàm `dispose()` của Provider, do đó không có memory leak nghiêm trọng từ Realtime listener. 

## 10. Performance issue
- **O(N) Recomputation:** Việc gọi hàm `WalletRepository.computeWalletsWithBalances(raw, txs)` khi stream ví thay đổi, duyệt qua MỌI giao dịch từ trước đến nay để tính số dư. Theo thời gian khi transaction lên đến hàng ngàn, đây là nút thắt cổ chai lớn nhất.
- **Lọc danh sách:** `TransactionProvider.filteredTransactions` tiến hành lọc (filter) và sắp xếp (sort) lại nguyên bộ danh sách list transaction lớn mỗi khi có bất kỳ sự thay đổi state nào khiến UI rebuild. Cần lưu lại cache hoặc tối ưu tính toán.
