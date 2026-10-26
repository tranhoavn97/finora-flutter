# FINORA Flutter Design System

Phiên bản: 4.0 — 08/09/2026  
Phạm vi: ứng dụng trong `flutter/lib/`  
Nguồn hình ảnh: FINORA Web hiện tại, hướng **Quiet Finance / Apple Blue**  
Nguyên tắc migration: giữ nguyên cấu trúc trang, dữ liệu và hành vi của Flutter cũ.

## 1. Mục tiêu

Design system này là nguồn chuẩn duy nhất cho giao diện Flutter. Mọi màn hình mới phải dùng semantic token và component chuẩn; không thêm mã màu, radius, shadow hay kích thước control trực tiếp trong feature.

Trải nghiệm cần tạo cảm giác bình tĩnh, rõ ràng và đáng tin cậy. Màu thương hiệu không cạnh tranh với màu tài chính. Thông tin tiền luôn dễ quét, còn hiệu ứng kính/gradient chỉ dùng ở vùng nhấn mạnh.

## 2. Kiến trúc source

### Nguồn chuẩn

- `core/design_system/v3/finora_v3_colors.dart`: màu semantic.
- `core/design_system/v3/finora_v3_tokens.dart`: spacing, radius, size.
- `core/design_system/v3/finora_v3_typography.dart`: kiểu chữ.
- `core/design_system/v3/finora_v3_theme.dart`: Material theme.
- `core/design_system/v3/finora_v3_components.dart`: component nền tảng.
- `core/widgets/finora/financial_components.dart`: component nghiệp vụ tài chính.
- `core/widgets/finora_navigation.dart`: app navigation.

### Lớp tương thích

`glass_widgets.dart`, `premium_widgets.dart` và `vikram_widgets.dart` đang được các trang cũ sử dụng. Có thể tiếp tục dùng trong lúc migration nhưng phải đọc màu từ theme. Không tạo thêm component mới tại ba file này.

### Quy tắc import

```dart
import 'package:finora/core/design_system/finora_design_system_v3.dart';
```

Feature không import trực tiếp file màu con nếu barrel file đã export component cần dùng.

## 3. Foundation tokens

### 3.1 Màu

| Vai trò | Light | Dark | Sử dụng |
|---|---:|---:|---|
| `canvas` | `#F9F8F6` | `#111418` | nền toàn app |
| `canvasRaised` | `#F1EFEA` | `#0B0E12` | vùng nền phân tầng |
| `surface` | `#FFFFFF` | `#161A1E` | card, modal, navigation |
| `surfaceTint` | `#F4F6F2` | `#20251F` | chip, icon tile, selected area |
| `border` | `#E2E8E0` | `#303731` | viền mặc định |
| `ink` | `#2C3329` | `#F8FAFC` | nội dung chính |
| `inkMuted` | `#667063` | `#CBD5E1` | mô tả, metadata |
| `brand` | `#007AFF` | `#0A84FF` | CTA, focus, selected |
| `brandStrong` | `#0062CC` | `#409CFF` | pressed, gradient |
| `positive` | `#087F5B` | `#20D69A` | thu nhập, hoàn tiền |
| `negative` | `#C43D4F` | `#FF6274` | chi tiêu, lỗi |
| `warning` | `#9A5B00` | `#FFBA45` | cảnh báo ngân sách |
| `purple` | `#8A6B3E` | `#D5B990` | premium, insight |

Không truyền ý nghĩa chỉ bằng màu. Số tiền phải có dấu `+`/`−`; lỗi có icon và nội dung; trạng thái selected có cả nền hoặc label.

### 3.2 Typography

| Style | Size | Weight | Dùng cho |
|---|---:|---:|---|
| Display | 32sp | 700 | onboarding/hero đặc biệt |
| Money hero | 28sp | 800 | tổng số dư |
| Page title | 22sp | 700 | tên màn hình |
| Section title | 17sp | 700 | tiêu đề nhóm |
| Body strong | 15sp | 700 | CTA, giá trị quan trọng |
| Body | 15sp | 400 | nội dung |
| Label | 13sp | 600 | label form, chip |
| Caption | 12sp | 400 | metadata |

Tiền dùng tabular figures. Không khóa `textScaleFactor`; UI phải hoạt động ở 200% font scale. Không dùng chữ nhỏ hơn 11sp.

### 3.3 Spacing và kích thước

- Thang spacing: `4, 8, 12, 16, 20, 24, 32, 40` dp.
- Padding trang: 16dp; tablet tối đa 24dp.
- Khoảng section: 24dp; khoảng card: 12dp.
- Touch target: tối thiểu 48×48dp.
- Button: 52dp; input: tối thiểu 56dp.
- Icon trong control: 20–24dp; category icon tile: 44dp.
- Bottom navigation: 72dp cộng safe area.
- Content width trên tablet: tối đa 720dp; form/modal tối đa 560dp.

### 3.4 Radius và elevation

- Icon tile: 12dp.
- Control: 16dp.
- Card: 20dp.
- Hero: 24dp.
- Dialog: 24dp.
- Bottom sheet: 28dp ở hai góc trên.
- Pill: 999dp.

Card thường dùng border 1dp và shadow mềm. Không xếp nhiều card có shadow lồng nhau. Blur chỉ dành cho navigation hoặc overlay nhỏ; surface chính phải đủ đặc để đọc tốt và giữ hiệu năng.

### 3.5 Motion và feedback

- Press: 100ms.
- Toggle/chip: 160ms.
- Tab/navigation: 240ms.
- Sheet/hero: 360ms.
- Tab/chip: `HapticFeedback.selectionClick()`.
- CTA chính: light impact; lưu giao dịch thành công: medium impact.
- Khi `MediaQuery.disableAnimationsOf(context)` là true, duration phải bằng zero.

## 4. Widget specification

### 4.1 App shell

#### `GlassScaffold`

Wrapper tương thích cho trang cũ. Nền phải đọc từ `context.v3.canvas`, body tự xử lý safe area, không gắn gradient riêng theo feature. Dùng cho màn hình cấp một hoặc form toàn trang.

#### `GlassTopBar`

- Cao theo Material toolbar, nút back có target 48dp.
- Title dùng Page title; subtitle dùng Caption.
- Tối đa hai action. Nhiều hơn chuyển vào overflow menu.
- Transparent trên canvas, không dùng shadow khi chưa scroll.

#### `FinoraNavigation`

- Bốn destination giữ cấu trúc hiện tại: Trang chủ, Giao dịch, Ví tiền, Cá nhân.
- Nút thêm giao dịch nằm giữa, 50–56dp, gradient `brand → brandStrong`.
- Selected dùng `brandSoft` + icon/label `brand`.
- Label luôn hiển thị và có semantics/tooltip.
- Navigation nổi có max-width 520dp và tôn trọng safe area.

### 4.2 Card và container

#### `FinoraSoftCard` — component chuẩn

- Padding mặc định 16dp; radius 20dp.
- Background `surface`; border `border`.
- Có `onTap` thì toàn card là touch target và dùng Ink response.
- Không tự chọn semantic color; feature truyền icon/accent phù hợp.

#### `GlassCard` — tương thích

Chỉ dùng cho trang chưa migrate. Visual phải tương đương `FinoraSoftCard`; không blur card danh sách dài.

#### `FrostedCard`

Chỉ dùng cho hero hoặc insight có nền trang trí. Không dùng làm row giao dịch, row cài đặt hoặc form field.

#### `LiquidListCard`

Container cho một nhóm list item. Divider thụt vào theo phần text, không chia xuyên qua icon. Một nhóm tối đa khoảng 7 item; dài hơn dùng list riêng.

### 4.3 Button

#### `FinoraFilledButton`

- CTA chính, cao 52dp, radius 16dp.
- Một màn hình/modal chỉ có một CTA chính nhìn thấy cùng lúc.
- Trạng thái: default, pressed (`brandStrong`), disabled (`surfaceTint`), loading.
- Loading giữ nguyên width/height và thay label bằng spinner 20dp.
- Icon leading 20dp, cách label 8dp.

#### `FinoraOutlinedButton`

Dùng cho hành động phụ hoặc cancel. Không dùng outline đỏ cho delete mặc định; delete nằm trong confirm modal với màu negative.

#### `FinoraIconButton`

Target 48dp, icon 22dp, tooltip bắt buộc nếu không có label. Nền `surfaceTint`; destructive icon dùng `negativeSoft`/`negative`.

#### `GlowPillButton`, `GradientButton`, `PrimaryButton`

Lớp tương thích. Chỉ giữ cho màn hình cũ; API mới phải dùng button V3. Glow chỉ được phép với CTA thêm giao dịch hoặc premium, không dùng cho hành động thường.

### 4.4 Form controls

#### `FinoraTextField` — component chuẩn

- Cao tối thiểu 56dp; label luôn rõ, hint không thay vai trò label.
- Border 1dp; focus 1.5dp màu brand; error màu negative.
- Prefix/suffix target 48dp nếu bấm được.
- Error text ngay dưới field, không chỉ snackbar.
- Keyboard type và autofill hint phải đúng dữ liệu.

#### Money input

- Căn phải hoặc theo convention của form hiện tại.
- Hiển thị phân cách hàng nghìn khi nhập nhưng lưu giá trị số nguyên/decimal sạch.
- Suffix `₫` không nằm trong controller value.
- Không cho số âm trừ workflow điều chỉnh chuyên biệt.

#### `SegmentedControl`

- Từ 2–4 lựa chọn; nhiều hơn dùng selection sheet.
- Cao ít nhất 48dp.
- Selected: nền brand, chữ trắng. Unselected: surface tint, chữ muted.
- Chuyển selection 160ms và có haptic.

#### `FilterChipX`, `CapsuleBadge`

- Chip tương tác tối thiểu 48dp; badge chỉ hiển thị trạng thái nên không giả dạng button.
- Chip selected dùng cả icon/check và màu.
- Badge semantic: success, warning, error, neutral.

#### `VikramToggleRow`

Toàn row bấm được; title Body strong, description Caption. Switch dùng brand khi on. Disabled giảm tương phản nhưng nội dung vẫn đọc được.

#### Date picker

`CustomDatePickerSheet` là chuẩn cho chọn một ngày. `PeriodPicker` dùng cho tháng/quý/năm/khoảng tùy chỉnh. Không dùng lẫn `showDatePicker` mặc định ở feature mới.

### 4.5 Financial widgets

#### `FinoraMoneyText` / `MoneyText`

- `neutral`: màu ink.
- `income`: màu positive và prefix `+`.
- `expense`: màu negative và prefix `−`.
- Giá trị ẩn hiển thị `••••••`, giữ kích thước layout.
- Hero 28sp/800; row 15sp/700.

#### `FinoraFinancialDelta`

Hiển thị icon hướng, phần trăm và kỳ so sánh. Giá trị 0 dùng neutral. Không nói “tốt/xấu” chỉ dựa vào tăng/giảm nếu ngữ cảnh là chi tiêu hoặc nợ.

#### `IncomeExpensePair`

Hai cột cân bằng, luôn có label. Ở width nhỏ hoặc font 200%, chuyển thành hai row thay vì overflow.

#### `TransactionRow`

- Category tile 44dp, radius 12dp.
- Tên giao dịch tối đa 2 dòng.
- Metadata tối đa 2 thông tin: ví và thời gian/chủ thể.
- Amount căn phải, không wrap; semantics đọc đầy đủ loại và số tiền.
- Swipe/delete chỉ thêm khi có phương án undo hoặc confirm.

#### `FinoraBudgetProgress`

- Luôn có đã dùng / hạn mức và phần trăm.
- `<80%`: brand/category; `80–99%`: warning; `≥100%`: negative.
- Progress bar cao 8dp, radius pill, không shadow.
- Trường hợp limit bằng 0 hiển thị trạng thái chưa thiết lập, không chia cho 0.

#### `FinanceShortcut` / `SquircleActionTile`

Quick action tile có target tối thiểu 72×72dp; icon 24dp trong tile 44dp; label tối đa 2 dòng. Grid ưu tiên 4 mục: Giao dịch, Ví, Ngân sách, Báo cáo.

### 4.6 States

#### `FinoraSkeleton`

Skeleton phải mô phỏng gần đúng layout thật, không chạy shimmer vô hạn khi reduce motion. Danh sách hiển thị 3–5 placeholder.

#### `FinoraEmptyState` / `EmptyState`

Bao gồm icon/illustration, title, mô tả ngắn và CTA tùy chọn. Empty không phải lỗi; không dùng màu negative.

#### `FinoraErrorState` / `ErrorStateWidget`

Nêu điều gì không tải được và có Retry nếu hành động có thể phục hồi. Chi tiết kỹ thuật chỉ xuất hiện trong debug.

#### `FinoraDataMessage`

Dùng cho inline loading/error/empty trong một section, không thay toàn màn hình nếu phần còn lại vẫn hoạt động.

## 5. Modal specification

### 5.1 Quy tắc chung

- Tác vụ ngắn, lựa chọn, filter: bottom sheet.
- Quyết định quan trọng hoặc xác nhận: dialog.
- Form dài hơn khoảng 5 field: full-screen page/modal route.
- Sheet dùng `useSafeArea: true`, `isScrollControlled: true` khi có keyboard hoặc nội dung dài.
- Modal max-width 560dp trên tablet; dialog max-width 420dp.
- Header: title, mô tả tùy chọn, close target 48dp.
- Footer CTA sticky khi nội dung scroll; keyboard không che field/CTA.
- Không lồng modal trong modal. Đóng modal hiện tại trước khi mở modal tiếp theo.
- Dismiss bằng barrier/drag bị khóa khi đang lưu hoặc có dữ liệu chưa lưu; phải có confirm bỏ thay đổi.

### 5.2 `GlassDialog`

Dialog tương thích chuẩn:

- Radius 24dp, surface đặc, padding 24dp.
- Title Section title; content Body; action cách nhau 8–12dp.
- Mobile rất hẹp: action xếp dọc, CTA chính ở cuối.
- Focus đầu tiên không tự động mở bàn phím trừ khi mục đích duy nhất là nhập liệu.

### 5.3 `GlassBottomSheet`

- Radius top 28dp; drag handle 32×4dp.
- Padding ngang 16dp, top 8/16dp, bottom gồm safe area.
- Chiều cao mặc định theo content; nội dung dài giới hạn khoảng 90% màn hình.
- Header và footer đứng yên nếu body cuộn dài.

### 5.4 Confirm delete

API chuẩn: `showConfirmDeleteDialog`.

- Title mô tả đúng đối tượng: “Xóa ví?”, “Xóa ngân sách?”.
- Body nêu hậu quả và dữ liệu liên quan.
- Cancel là outlined/text; Delete là filled màu negative.
- Focus mặc định vào Cancel; không dùng “Có/Không” mơ hồ.
- Với soft delete có thể hoàn tác, snackbar cung cấp Undo.

### 5.5 Transaction filter sheet

Component: `TransactionFilterSheet`.

- Nhóm: loại giao dịch, thời gian, ví/category, chủ thể.
- Hiển thị số filter đang áp dụng.
- Hai action sticky: “Đặt lại” và “Áp dụng”.
- Đặt lại chỉ cập nhật draft; kết quả chỉ thay đổi khi Apply.
- Mở lại phải phản ánh chính xác filter đang dùng.

### 5.6 Period picker

Component: `PeriodPicker`.

- Preset: tháng này, tháng trước, quý, năm và tùy chỉnh.
- Custom range bắt buộc `from ≤ to`.
- Title của trang phải phản ánh kỳ đã chọn.
- Dữ liệu timezone/local date không được đổi ngày ngoài ý muốn.

### 5.7 Date picker sheet

Component: `CustomDatePickerSheet`.

- Header hiển thị ngày đang chọn rõ ràng.
- Calendar có trạng thái today, selected, disabled và outside month.
- Nút “Hôm nay”, “Hủy”, “Chọn”.
- Ngày không hợp lệ không thể tap và có semantics disabled.

### 5.8 Selection sheets trong giao dịch

Dùng cho chọn ví, category, thành viên và loại giao dịch.

- Có search nếu danh sách trên 8 item.
- Row cao tối thiểu 56dp, icon 40–44dp.
- Selected có check + brandSoft.
- Tùy chọn tạo mới nằm cuối danh sách và phân cách rõ.
- Sau chọn, sheet trả value; không trực tiếp mutation form bên ngoài trong builder.

### 5.9 Transaction detail/history

- `showTransactionDetailSheet`: quick detail + edit/delete action.
- `TransactionHistorySheet`: lịch sử liên quan tới ví/category/budget.
- Detail ưu tiên receipt hierarchy: loại + amount, category, ví, ngày, note, owner.
- History sheet cao tối đa 90%, filter/header cố định, list cuộn.
- Edit mở full-screen `AddTransactionPage`; delete dùng confirm dialog.

### 5.10 Wallet detail sheet

Component hiện tại: `_WalletTransactionSheet`.

- Header có icon, tên ví, số dư và loại ví.
- Credit card phải phân biệt hạn mức, dư nợ và khả dụng.
- Tab/list lịch sử dùng cùng `TransactionRow` chuẩn.
- Action edit/delete không cạnh tranh với số dư chính.

### 5.11 Goal deposit dialog

Component hiện tại: `_DepositDialog`.

- Hiển thị mục tiêu, đã tích lũy, còn thiếu.
- Input số tiền + chọn ví; không cho vượt điều kiện nghiệp vụ nếu không xác nhận.
- CTA “Nạp vào mục tiêu”; loading ngăn double submit.
- Thành công đóng dialog rồi cập nhật stream/snackbar.

### 5.12 Loan repayment dialog

Component hiện tại: `_RepayDialog`.

- Hiển thị dư nợ hiện tại, tiền trả, ngày, nguồn ví.
- Cảnh báo khi số tiền lớn hơn dư nợ.
- CTA ghi rõ “Ghi nhận trả nợ”, không dùng “Lưu” chung chung.
- Thành công cập nhật khoản vay, giao dịch và ví như một workflow nhất quán.

### 5.13 Range và unsaved-change dialogs

Các `AlertDialog` trực tiếp trong Dashboard, Family, Goal, Settings cần migrate về dialog chuẩn. Nội dung phải dùng semantic token, action label rõ và responsive khi font scale lớn.

## 6. Page templates

### Dashboard

Page header → balance hero → quick actions → health/budget insight → recent transactions. Chỉ hero được dùng gradient lớn. Privacy toggle phải che tất cả số tiền trên trang.

### List page

Page header + action → search/filter → summary tùy chọn → list/empty/error. Áp dụng cho giao dịch, ví, category, budget, goal, loan, asset và notification.

### Form page

Top bar + progress/context tùy chọn → section card → sticky CTA. Validation inline; dữ liệu chưa lưu có confirm khi back.

### Settings/Profile

Thông tin tài khoản ở trên, nhóm setting theo chủ đề trong `LiquidListCard`. Toggle dùng row đầy đủ; destructive account action nằm cuối và tách khỏi preference thường.

## 7. Accessibility checklist

- Contrast body ≥ 4.5:1; large text ≥ 3:1.
- Touch target ≥ 48dp.
- Test width 320, 360, 412 và tablet.
- Test font scale 100%, 150%, 200%.
- Icon-only có tooltip và semantic label.
- Chart có textual summary; không phụ thuộc chỉ vào màu.
- Modal focus hợp lý, đọc đúng title trước content.
- Số tiền được screen reader đọc với loại thu/chi và đơn vị.
- Dark mode không dùng pure black/white trên diện tích lớn.

## 8. Migration map

| Hiện tại | Đích chuẩn | Trạng thái |
|---|---|---|
| `GlassCard`, `FrostedCard` | `FinoraSoftCard` | migrate dần |
| `PrimaryButton`, `GradientButton`, `GlowPillButton` | `FinoraFilledButton` / `FinoraOutlinedButton` | migrate dần |
| `GlassTextField`, Premium `FinoraTextField` | V3 `FinoraTextField` | migrate dần |
| Feature money `Text` tự tô màu | `FinoraMoneyText` | bắt buộc khi sửa màn hình |
| Row giao dịch tự dựng | `TransactionRow` | bắt buộc khi sửa màn hình |
| `AlertDialog` trực tiếp | `GlassDialog` hoặc dialog V3 kế nhiệm | migrate dần |
| Sheet tự dựng | `GlassBottomSheet` | migrate dần |
| Mã màu hard-code | `context.v3` | không thêm mới |

Thứ tự migration: app shell → dashboard → transaction → wallet → budget/report → category/goal/loan/asset → profile/settings/family/notification/AI.

## 9. Definition of done cho một widget/modal

- Dùng semantic token, không có mã màu/spacing hard-code ngoài trường hợp minh họa dữ liệu.
- Có default, pressed/focused, disabled, loading, error và empty nếu phù hợp.
- Hoạt động cả light/dark.
- Không overflow ở 320dp và font scale 200%.
- Có semantics, tooltip và haptic phù hợp.
- Không thay đổi contract dữ liệu hoặc business logic của feature.
- Có widget test cho render chính và ít nhất một trạng thái biên.
- Xuất hiện trong `/design-system` gallery trước khi dùng rộng rãi.

## 10. Ví dụ chuẩn

```dart
final colors = context.v3;

FinoraSoftCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Chi tiêu tháng này', style: FinoraV3Typography.sectionTitle),
      const SizedBox(height: FinoraV3Space.x2),
      const FinoraMoneyText(
        '−2.350.000 ₫',
        kind: FinoraMoneyKind.expense,
      ),
      const SizedBox(height: FinoraV3Space.x4),
      FinoraFilledButton(
        label: 'Thêm giao dịch',
        onPressed: onAddTransaction,
      ),
    ],
  ),
)
```

Mọi quyết định giao diện mới phải cập nhật tài liệu và gallery cùng lúc để code, thiết kế và QA dùng chung một nguồn chuẩn.
