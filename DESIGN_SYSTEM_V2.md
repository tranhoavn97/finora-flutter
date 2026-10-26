# FINORA Design System 2.0 — Flutter Android

## 1. Hướng thiết kế

FINORA dùng ngôn ngữ **Calm Fintech**: rõ ràng, đáng tin và nhẹ mắt khi xem số liệu lâu. Sapphire là màu thương hiệu và hành động chính; xanh lá, coral, amber chỉ biểu thị trạng thái tài chính. Giao diện ưu tiên Material 3, light/dark mode và Android trước.

Ba nguyên tắc:

1. **Số tiền là nội dung chính** — dùng tabular figures, tương phản cao, không dùng gradient cho mọi thẻ.
2. **Mỗi màu có một nhiệm vụ** — xanh thương hiệu không đồng nghĩa với thu nhập; coral chỉ dành cho chi tiêu/lỗi; gold chỉ dành cho premium.
3. **Một màn hình, một hành động chính** — chỉ một nút Filled nổi bật trong viewport; các thao tác còn lại dùng Outlined, Text hoặc Icon button.

## 2. Foundation

### Màu

| Vai trò | Light | Dark | Cách dùng |
|---|---:|---:|---|
| Primary | `#2563EB` | Material dark mapping | CTA, selected state, link |
| Background | `#F5F6F8` | `#0D0E11` | nền app |
| Surface | `#FFFFFF` | `#16171B` | card, sheet, dialog |
| Text primary | `#17191E` | `#F8FAFC` | tiêu đề, số tiền |
| Text secondary | `#60646F` | `#A9ACB5` | label, mô tả |
| Income | `#087F5B` | `#54D8A3` | thu nhập, tăng trưởng |
| Expense | `#C43D4F` | `#FF8995` | chi tiêu, giảm |
| Warning | `#9A5B00` | `#FFC463` | sắp vượt hạn mức |
| Premium | `#7A5700` | `#FFD66E` | gói premium duy nhất |

Trong widget, ưu tiên `Theme.of(context).colorScheme` và `context.semanticColors`. Không gọi trực tiếp màu raw cho feature mới.

### Typography

- Page title: 22/700.
- Section title: 20/600.
- Card title: 17/600.
- Body: 17/400; form/helper có thể dùng 16 hoặc 15.
- Caption: 12/400; không dùng nhỏ hơn 11sp.
- Money: 24/700 với `FontFeature.tabularFigures()`; số hero có thể 34/700.
- Tôn trọng text scaling của Android; không khóa `textScaler`.

### Spacing và kích thước

- Lưới 4dp: `4, 8, 12, 16, 20, 24, 32, 40`.
- Page padding compact: 16dp (14dp chỉ dùng cho list dày hiện hữu trong giai đoạn migrate).
- Khoảng cách section: 24dp; item trong một group: 8–12dp.
- Touch target tối thiểu: 48×48dp.
- Button: cao 52dp; input: cao tối thiểu 56dp.
- Card radius 24dp; button radius 20dp; input 22dp; sheet top radius 32dp.

### Elevation và motion

- Card mặc định dùng border 1dp, elevation 0.
- Chỉ floating dock/menu dùng shadow; dark mode tránh glow màu.
- Motion: 150ms cho feedback, 250ms cho state/navigation, 350ms cho sheet. Hỗ trợ reduce motion ở các animation trang trí.

## 3. Component contract

### Button

- `FilledButton`: tạo giao dịch, lưu form, xác nhận luồng chính.
- `OutlinedButton`: Google sign-in, thao tác phụ có nhãn.
- `TextButton`: filter phụ, link, bỏ qua.
- `IconButton`: luôn có `tooltip` và vùng chạm 48dp.
- Loading giữ nguyên kích thước nút, disable double tap và có semantic label.

### Input

- Label luôn tồn tại; hint chỉ là ví dụ, không thay label.
- Error nằm dưới field và mô tả cách sửa.
- Bàn phím số tiền dùng decimal; nút Next/Done đúng theo thứ tự form.
- Tiền tệ hiển thị theo locale `vi_VN`, không lưu chuỗi đã format.

### Finance card

- Thứ tự: label → giá trị → delta/context.
- Dương/âm không chỉ truyền đạt bằng màu: luôn kèm dấu, icon hoặc text.
- Số tiền mặc định căn phải trong list; dùng tabular figures.
- Skeleton giữ đúng kích thước nội dung thật; empty state không hiển thị dữ liệu mẫu.

### Navigation và sheet

- Compact `<600dp`: bottom navigation; medium `600–839dp`: navigation rail; expanded `≥840dp`: rail + content tối đa 680dp.
- Bottom sheet có drag handle, title, nội dung scroll và CTA cố định bên dưới nếu form dài.
- FAB/add transaction không che navigation hoặc phần tử cuối danh sách.

### State bắt buộc

Mọi màn hình/component có đủ: loading, empty, error có retry, offline/stale nếu liên quan, disabled, pressed/focused/selected. Xóa hoặc chuyển tiền phải có confirm và haptic phù hợp.

## 4. Accessibility & content

- Text thường đạt tối thiểu WCAG AA 4.5:1; text lớn 3:1.
- Không dùng màu là tín hiệu duy nhất. Icon không nhãn phải có tooltip/semantic label.
- Kiểm thử ở 320dp, 360dp, 412dp và text scale 200%.
- Copy tiếng Việt ngắn, trực tiếp: “Chi tiêu”, “Thu nhập”, “Số dư khả dụng”. Không dùng badge hoặc số liệu giả.
- Giá trị riêng tư phải được che đồng thời trên toàn summary, không chỉ hero balance.

## 5. Cách dùng trong Flutter

```dart
import 'package:finora/core/design_system/finora_design_system.dart';

final colors = Theme.of(context).colorScheme;
final finance = context.semanticColors;

Text(
  '+2.500.000 ₫',
  style: AppTypography.numericValue.copyWith(color: finance.income),
);
```

Theme hiện được cấu hình tập trung tại `lib/core/design_system/app_theme.dart`, gồm typography mapping, button, input, chip, card, dialog, sheet, navigation, tooltip và semantic finance colors.

## 6. Thứ tự migrate UI

1. Dashboard + bottom navigation: thiết lập hierarchy và responsive shell.
2. Add transaction + transaction list: chuẩn hóa input, amount, status và filter.
3. Wallet, budget, report: dùng chung finance card và empty/loading/error state.
4. Auth, profile, settings: dọn legacy gradient/glass và chuẩn hóa form.
5. Xóa các màu/radius hard-code còn lại sau khi visual regression đã ổn định.

Definition of done cho từng màn hình: không có màu/spacing tùy ý mới, light/dark đầy đủ, không overflow ở 320dp và 200% text, touch target 48dp, analyzer/test pass.
