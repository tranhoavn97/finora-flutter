# FINORA Design System 3.0

**Soft · Modern · Fintech**  
Tài chính tốt hơn cho một cuộc sống đẹp hơn.

## 1. Visual direction

FINORA 3.0 dùng “Calm Fintech + Soft Neumorphism + Subtle Glass” trên nền Material 3. Surface đủ đặc để đảm bảo tương phản và hiệu năng Android.

- Light mode: nền neutral `#F5F6F8`, card trắng, viền và shadow nhẹ.
- Dark mode: nền `#0D0E11`, card `#16171B`, depth tập trung ở navigation và CTA.
- Blue là thương hiệu và trạng thái được chọn.
- Green = thu nhập/tích cực; red = chi tiêu/lỗi; amber = cảnh báo; purple = ngân sách/giải trí.
- Gradient chỉ dùng cho logo, CTA chính, hero balance và thẻ ngân hàng.

## 2. Color tokens

### Brand & surface

| Token | Light | Dark | Vai trò |
|---|---:|---:|---|
| Canvas | `#F5F6F8` | `#0D0E11` | nền ứng dụng |
| Surface | `#FFFFFF` | `#16171B` | card, dock |
| Surface tint | `#EAF2FF` | `#202126` | icon button, chip |
| Border | `#DCE8FA` | `#2A2C32` | viền card |
| Ink | `#17191E` | `#F8FAFC` | tiêu đề, số tiền |
| Ink muted | `#60646F` | `#A9ACB5` | mô tả |
| Brand | `#2563EB` | `#6D9CFF` | CTA, selected |
| Cyan | `#48C7FF` | `#48D7FF` | gradient highlight |

### Finance semantic

| Token | Light | Dark | Vai trò |
|---|---:|---:|---|
| Positive | `#087F5B` | `#20D69A` | thu nhập, tăng trưởng |
| Negative | `#C43D4F` | `#FF6274` | chi tiêu, lỗi |
| Warning | `#9A5B00` | `#FFBA45` | sắp vượt ngân sách |
| Premium | `#7A5700` | `#9078FF` | gói premium/insight |

Màu tài chính luôn kèm dấu `+ / −`, icon hoặc text; không truyền đạt ý nghĩa chỉ bằng màu.

## 3. Typography

- Display/hero: 32sp, weight 700.
- Page title: 22sp, weight 700.
- Section title: 17sp, weight 700.
- Body: 15sp, line-height 145%.
- Label: 13sp, weight 600.
- Caption: 12sp; không dùng text nhỏ hơn 11sp.
- Money hero: 28sp, weight 800, tabular figures.
- Money row: 15sp, weight 700, tabular figures.

Không khóa text scale. Toàn bộ màn hình phải hoạt động ở Android font scale 200%.

## 4. Layout tokens

- Spacing: `4, 8, 12, 16, 20, 24, 32, 40`.
- Page padding: 16dp.
- Icon tile radius: 12dp.
- Control radius: 16dp.
- Card radius: 20dp.
- Hero radius: 24dp.
- Bottom sheet: 28dp ở hai góc trên.
- Button: 52dp; input tối thiểu 56dp; touch target tối thiểu 48dp.
- Bottom navigation: 72dp + safe area.

## 5. Elevation & glass

Ba cấp surface:

1. Canvas: không shadow.
2. Card: border 1dp + shadow xanh mềm `0 10 28 -6` trong light mode.
3. Floating action: gradient blue/cyan + glow; chỉ dành cho nút thêm giao dịch.

Không blur toàn màn hình. Nếu dùng blur cho hero/card, giới hạn vùng nhỏ và có màu nền fallback để giữ hiệu năng máy Android tầm trung.

## 6. Component rules

### Summary hero

- Label nhỏ → số dư lớn → delta theo kỳ.
- Eye toggle che mọi số tiền nhạy cảm trên màn hình, không chỉ số dư.
- Gradient/aurora chỉ làm nền nhẹ, không ảnh hưởng khả năng đọc.

### Quick action

- Grid bốn mục: Giao dịch, Ví, Ngân sách, Báo cáo.
- Icon tile có semantic color; label giữ màu trung tính.
- Cả tile là touch target, không chỉ icon.

### Transaction row

- Icon category 40–44dp.
- Tên + metadata bên trái; amount căn phải.
- Income xanh và có `+`; expense đỏ và có `−`.
- Metadata tối đa hai phần quan trọng: nguồn tiền và thời gian/chủ thể.

### Filter and segmented control

- Selected dùng blue gradient hoặc brand solid.
- Unselected dùng surface tint, không dùng border dày.
- Tối đa 4 lựa chọn trong segmented control; nhiều hơn dùng sheet/dropdown.

### Budget progress

- Luôn hiển thị đã dùng / hạn mức và phần trăm.
- 0–79% dùng brand/category color; 80–99% warning; ≥100% negative.
- Thanh progress không dùng shadow hoặc viền trang trí.

### Bottom navigation

- 5 vị trí: Tổng quan, Ví, Giao dịch, Ngân sách, Báo cáo.
- Nút Giao dịch ở giữa là floating primary action.
- Selected state dùng cả màu và label; icon-only phải có semantic label.

## 7. Motion & feedback

- 100ms: press feedback.
- 160ms: chip/toggle.
- 240ms: tab/navigation state.
- 360ms: sheet/hero transition.
- Haptic selection cho tab/chip; light impact cho CTA; medium impact sau khi lưu giao dịch.
- Tôn trọng reduce motion; không có animation lặp vô hạn.

## 8. Accessibility

- Body text ≥ 4.5:1, large text ≥ 3:1.
- Touch target ≥ 48×48dp.
- Test ở 320, 360, 412dp và font scale 100%, 150%, 200%.
- Chart có mô tả semantics và không phụ thuộc duy nhất vào màu.
- Dark mode không dùng pure black/pure white trên diện tích lớn để giảm chói.

## 9. Flutter usage

```dart
import 'package:finora/core/design_system/finora_design_system_v3.dart';

MaterialApp(
  theme: buildFinoraV3Theme(Brightness.light),
  darkTheme: buildFinoraV3Theme(Brightness.dark),
);

final tokens = context.v3;
Text(
  '-65.000 ₫',
  style: FinoraV3Typography.money.copyWith(color: tokens.negative),
);
```

## 10. Migration boundary

Design System 3.0 được xây độc lập trong `lib/core/design_system/v3/`. Chưa thay từng màn hình ở giai đoạn này. Khi migrate, thực hiện theo thứ tự: app shell/navigation → dashboard → transaction → wallet → budget → report; mỗi màn hình hoàn thành cả light và dark trước khi chuyển màn hình tiếp theo.
