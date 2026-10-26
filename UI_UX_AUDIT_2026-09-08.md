# FINORA Flutter — UI/UX Audit

Ngày audit: 08/09/2026  
Phạm vi: Flutter Web preview từ source Android hiện tại, viewport mobile; đối chiếu source trong `flutter/lib/`.  
Trạng thái: read-only audit, không thay đổi dữ liệu người dùng.

## 1. Kết luận nhanh

App đã có cấu trúc chức năng tốt, dữ liệu thật và các luồng tài chính tương đối đầy đủ. Tuy nhiên giao diện chưa thể được xem là một design system thống nhất. Các màn hình đang pha trộn ít nhất ba phong cách: blue/cyan fintech, orange/purple gradient và quiet sage. Điều này làm sản phẩm có cảm giác như nhiều app ghép lại dù từng màn hình riêng lẻ khá hoàn thiện.

Điểm mạnh nhất là hierarchy ở Wallet, form thêm giao dịch dễ hiểu và nhóm chức năng trong Profile rõ. Điểm yếu lớn nhất là consistency, accessibility ở text/touch target, information architecture của navigation và các modal chưa cùng một contract.

Không phát hiện blocker P0 trong lượt audit trực quan này. Có 8 nhóm P1 cần sửa trước khi phát hành diện rộng.

## 2. Bằng chứng audit

### Màn hình đã kiểm tra trực tiếp

- Dashboard/Tổng quan.
- Giao dịch và filter bottom sheet.
- Ví & Tài khoản.
- Cá nhân/Profile.
- Báo cáo & phân tích.
- Ngân sách.
- Mục tiêu tiết kiệm.
- Khoản vay & Nợ.
- Form thêm giao dịch.

### Bằng chứng source

- 621 lần khai báo `Color(0x...)` trực tiếp trong feature.
- 64 lần dùng component Glass legacy trong feature.
- Chỉ 37 vị trí feature đang dùng V3 token/component.
- 11 lời gọi bottom sheet, 7 lời gọi dialog và 5 `AlertDialog` dựng trực tiếp.
- Nhiều label 9.5–11.5sp và control/icon container dưới 48dp.
- Các component cùng vai trò đang tồn tại ở V3, Glass, Premium và Vikram.

## 3. Findings ưu tiên

### P1 — Ngôn ngữ thị giác không thống nhất

Quan sát:

- App shell và CTA dùng Apple Blue `#007AFF` theo brand direction mới.
- Dashboard và Wallet vẫn dùng cyan/blue gradient mạnh.
- Report dùng navy/cyan.
- Budget dùng orange gradient.
- Goal dùng blue selected state và blue border.
- Loan dùng green hero nhưng CTA “Thêm” lại purple/blue.

Tác động: giảm nhận diện thương hiệu, trạng thái semantic bị lẫn với màu trang trí, người dùng khó hình thành mô hình giao diện ổn định.

Khuyến nghị: đóng băng palette trang trí, thay toàn bộ màu trực tiếp bằng semantic token. Apple Blue cho interactive state; green/red/amber chỉ cho ý nghĩa tài chính; gradient chỉ dùng hero và CTA trung tâm.

Tiêu chí hoàn tất: không còn màu brand hard-code trong feature; mỗi màn hình qua light/dark visual regression.

### P1 — Navigation che khuất các module chính

Navigation hiện chỉ có Trang chủ, Giao dịch, Ví tiền, Cá nhân và nút thêm giữa. Report, Budget, Goal, Loan, Category, Asset, Family, AI đều bị đặt sâu trong Profile hoặc quick action không ổn định.

Tác động: “Cá nhân” vừa là hồ sơ vừa là menu toàn app; người dùng phải nhớ vị trí chức năng và thêm một bước cho tác vụ thường xuyên.

Khuyến nghị:

- Giữ 4 tab + CTA nếu đây là cấu trúc sản phẩm đã chốt.
- Đổi “Cá nhân” thành “Thêm” hoặc “Quản lý” nếu trang tiếp tục chứa toàn bộ module.
- Profile/account riêng đặt ở header của trang Quản lý.
- Dashboard quick actions phải dẫn nhất quán đến Giao dịch, Ví, Ngân sách, Báo cáo.
- AI nên là floating assistant hoặc shortcut rõ, không lúc là tab lúc là card.

### P1 — Accessibility: text nhỏ và touch target thiếu chuẩn

Source có nhiều font 9.5–11.5sp và control 32–46dp. Ví dụ nav label 10.5sp, metadata card 10.5/11sp, button/header icon 38–42dp.

Tác động: khó đọc, khó bấm, dễ overflow ở Android font scale 150–200%, không đạt mục tiêu touch target 48dp.

Khuyến nghị: caption tối thiểu 12sp, body 15sp; mọi vùng tương tác tối thiểu 48×48dp. Test bắt buộc tại width 320/360/412 và font scale 100/150/200%.

### P1 — CTA disabled không phân biệt được trạng thái

Quan sát ở Ngân sách và Thêm giao dịch: button disabled có label tối và tương phản thấp, trông gần giống enabled. Không rõ lý do button bị vô hiệu hóa.

Tác động: người dùng không biết có thể bấm hay thiếu dữ liệu gì.

Khuyến nghị:

- Disabled: nền neutral `surfaceTint`, chữ `inkSubtle`, không glow.
- Nếu CTA bị khóa do validation, hiển thị inline error hoặc helper cạnh field thiếu.
- Với amount bằng 0, label/helper nêu “Nhập số tiền lớn hơn 0”.
- Không dùng opacity đơn thuần khiến contrast không kiểm soát.

### P1 — Privacy mode chưa bao phủ dữ liệu tài chính

Dashboard, Wallet, transactions, goals và loans hiển thị nhiều số tiền. Audit kiến trúc trước đó cho thấy Flutter chưa có global privacy state tương đương web.

Tác động: rủi ro lộ dữ liệu khi dùng app nơi công cộng; toggle cục bộ nếu có không đảm bảo che toàn bộ tiền.

Khuyến nghị: một privacy state toàn app, persisted, dùng chung qua `FinoraMoneyText`; che cả hero, list, chart tooltip, wallet, debt, goal và report.

### P1 — Modal không có một contract thống nhất

Bottom sheet filter khá tốt về bố cục nhưng toàn app dùng nhiều cách dựng modal. Có `GlassDialog`, `GlassBottomSheet`, `AlertDialog` trực tiếp và sheet riêng từng feature.

Tác động: padding, radius, keyboard behavior, CTA order, dismiss behavior và semantics khác nhau.

Khuyến nghị: chỉ còn `FinoraDialog` và `FinoraBottomSheet` làm primitives; mọi modal dùng header/body/sticky footer chung. Form dài hơn 5 field dùng full-screen route.

### P1 — Responsive mới tối ưu cho mobile hẹp

Preview web giữ cột mobile, nhưng source có nhiều kích thước cố định và layout ngang dày đặc. Các hero chứa 3–5 số liệu dễ vỡ khi font lớn; goal filter có 4 pill trên một hàng.

Tác động: trải nghiệm tablet/web lãng phí diện tích; font lớn có nguy cơ overflow.

Khuyến nghị: compact <600, medium 600–839, expanded ≥840. Mobile dùng một cột; tablet dùng master/detail hoặc grid 2 cột; content max-width 680–720dp. Segmented control dài chuyển scroll hoặc dropdown.

### P1 — Trạng thái dữ liệu chưa nói rõ freshness/sync

Các trang hiển thị dữ liệu Firebase nhưng không có trạng thái offline, pending write hoặc last sync nhất quán. Empty state có thể bị hiểu nhầm là chưa có dữ liệu dù stream lỗi/chưa sync.

Tác động: giảm niềm tin vào số dư và báo cáo tài chính.

Khuyến nghị: phân biệt loading, empty, offline-cache, syncing, error; hiển thị badge nhỏ ở header và không xóa dữ liệu cũ khi refresh thất bại.

## 4. Findings theo màn hình

### Dashboard

Điểm tốt:

- Thứ tự hero → quick actions → health → wallets → budget → recent activity hợp lý.
- Summary có cả tài sản, cho vay, thu/chi và kỳ thời gian.
- Quick action dùng icon và label, dễ hiểu.

Vấn đề:

- Mật độ màu/gradient quá cao; wallet cards cạnh health card cạnh hero cùng tranh sự chú ý.
- “Trợ lí Finora — Báo động 90/100” dùng ngôn ngữ gây lo lắng nhưng không giải thích nguyên nhân/hành động.
- Card ví ngang bị cắt, item kế tiếp chỉ lộ một phần; affordance scroll chưa rõ.
- Budget 0/0 vẫn hiển thị 0%, tạo cảm giác có dữ liệu thay vì “chưa thiết lập”.
- Header/hero bị dài và nhiều thông tin ở màn nhỏ.

Đề xuất: chỉ hero có gradient; wallet/health dùng surface trắng. Đổi health copy thành “Sức khỏe tài chính” + insight hành động. Budget 0/0 dùng empty mini-state. Thêm page indicator/peek có chủ ý cho carousel.

### Giao dịch

Điểm tốt:

- Amount căn phải, income/expense phân biệt rõ.
- Metadata ví + thời gian đủ dùng.
- Danh sách quét nhanh và khoảng cách row ổn.

Vấn đề:

- Icon tất cả giao dịch đều giống tiền mặt, không hỗ trợ nhận biết category.
- Summary thiếu ký hiệu tiền tệ (`138.099.950` không có `₫`).
- Hai icon header filter/sort không có label trực quan trong UI.
- Transfer đang dùng blue giống link/brand; semantic transfer cần neutral/info riêng.
- Card cho từng row tạo nhiều khối nổi, danh sách dài có cảm giác nặng.

Đề xuất: category icon thật; dùng grouped surface với divider; thêm `₫`; tooltip/semantics và badge số filter; sticky month grouping.

### Filter giao dịch

Điểm tốt:

- Grouping Thành viên, Loại, Thời gian, Danh mục rõ.
- “Đặt lại” và CTA “Áp dụng bộ lọc” đúng mental model.

Vấn đề:

- Close chỉ là drag/dismiss, thiếu nút close hiển thị.
- Chip selected có check nhưng chiều cao khá nhỏ.
- CTA sát đáy, cần safe-area/keyboard verification.
- Accessibility tree chỉ đọc checkbox 0/1 ở nhiều mục, chưa gắn label đầy đủ.

Đề xuất: label semantics cho mỗi chip; target 48dp; header có close 48dp; footer sticky + safe area; hiển thị số kết quả dự kiến nếu rẻ để tính.

### Ví & Tài khoản

Điểm tốt:

- Đây là màn hình hoàn chỉnh nhất về hierarchy.
- Phân tách credit card và cash/account rõ.
- Tổng tài sản, tiền khả dụng và dư nợ nằm cùng hero.
- Owner filter hữu ích cho family finance.

Vấn đề:

- Hero cyan và credit cards nhiều màu làm tổng thể quá rực.
- Carousel credit card cắt card tiếp theo không có điều khiển rõ.
- “Thêm thẻ” và “Thêm tài khoản” nhỏ, gần mép.
- Các số tài chính nhạy cảm chưa có privacy mode chung.
- Nhãn “Chồng/Vợ” lặp trong cả tên và chip ở một số tài khoản.

Đề xuất: Apple Blue hero nhẹ hơn; card ngân hàng giữ màu thương hiệu nhưng giảm glow; standard hóa add action; tránh lặp owner; thêm privacy toggle và balance semantics.

### Cá nhân / Quản lý

Điểm tốt:

- Group tài chính và cài đặt rõ.
- Row list dễ quét, icon màu hỗ trợ nhận biết.

Vấn đề:

- Tên “Hồ sơ cá nhân” không phản ánh vai trò hub quản lý toàn app.
- Hai nhóm card sát nhau nhưng nhóm thứ hai chưa có heading.
- “Bảo mật & Mật khẩu” trên Firebase/Google cần phản ánh đúng provider; không hứa chức năng đổi mật khẩu khi tài khoản Google không có password.
- Currency/language có thể bị khuất dưới bottom nav nếu padding cuối không đủ.

Đề xuất: đổi thành “Quản lý” hoặc “Khác”; thêm section heading “Ứng dụng & tài khoản”; provider-aware security; bottom padding bằng nav height + safe area + 16.

### Báo cáo

Điểm tốt:

- Member segmentation và chọn tháng dễ thấy.
- Hero dòng tiền có cấu trúc đơn giản.

Vấn đề:

- Màn empty để lại khoảng trắng rất lớn.
- Empty card chỉ có câu thông báo, không CTA tạo giao dịch hoặc đổi kỳ.
- Hero cyan không cùng brand.
- “0 giao dịch”, “0đ” lặp nhiều nhưng không thêm insight.
- Cơ cấu chi tiêu chỉ có card trống; không có textual summary/chart accessibility khi có data cần xác minh.

Đề xuất: empty state có CTA “Thêm giao dịch” và “Chọn tháng khác”; compact hero khi empty; chart có legend + summary; sage/semantic token.

### Ngân sách

Điểm tốt:

- Tổng hạn mức, đã chi và còn lại đặt đúng hierarchy.
- Empty state có giải thích và CTA.

Vấn đề:

- Orange gradient được dùng khi chưa có cảnh báo, làm sai semantic warning.
- 0/0 hiển thị 0% không có ý nghĩa.
- CTA disabled có nền/chữ tương phản kém và không nói lý do.
- Có cả nút `+` header và CTA empty cho cùng hành động; trạng thái disabled giữa hai nơi có thể khác nhau.

Đề xuất: hero brand neutral; chỉ chuyển amber khi ≥80%; empty bỏ progress 0/0; một CTA chính; giải thích nếu thiếu category/quyền.

### Mục tiêu

Điểm tốt:

- Tổng tích lũy và tổng mục tiêu rõ.
- Filter trạng thái phù hợp.
- Card mục tiêu có deadline, tiến độ và overflow action.

Vấn đề:

- Summary blue border và selected state chưa dùng cùng Apple Blue token.
- Số tiền xuất hiện gạch chân, dễ bị hiểu là link.
- 4 filter pill trên một hàng có nguy cơ overflow khi font lớn.
- Card mục tiêu 4 tỷ nhưng 0% không có “cần tiết kiệm mỗi tháng” hoặc next action.

Đề xuất: loại bỏ underline; responsive filters; hiển thị monthly required/remaining time; status badge; progress màu brand/warning/positive.

### Khoản vay & Nợ

Điểm tốt:

- Tách “Cho vay/Vay nợ” rõ.
- Tổng cần thu và số khoản dễ hiểu.
- “Thu một phần” là action sát nhu cầu thực.

Vấn đề:

- CTA thêm purple, hero green và selected blue cùng xuất hiện.
- Edit/delete icon nhỏ, gần nhau, không đủ touch target rõ.
- Delete icon lộ trực tiếp trên mọi row gây rủi ro thao tác nhầm.
- Số tiền gạch chân tạo affordance giả.
- Row thiếu ngày đến hạn/trạng thái quá hạn.

Đề xuất: menu overflow chứa edit/delete; action chính “Thu một phần” giữ riêng; thêm due/status; bỏ underline; semantic color theo direction của khoản vay.

### Thêm giao dịch

Điểm tốt:

- Flow một trang rõ: loại → số tiền → category → ví → ngày → ghi chú.
- Field dạng selection row dễ bấm.
- CTA sticky phù hợp trên mobile.

Vấn đề:

- 5 loại trên một segmented row có thể quá chật, đặc biệt font lớn.
- Selected state blue trong khi CTA sage.
- CTA disabled không giải thích amount=0 và có contrast thấp.
- Ghi chú chiếm chiều cao như input một dòng nhưng intent có thể là multiline.
- Chưa thấy summary tác động số dư trước khi lưu cho transfer/pay card/investment.

Đề xuất: loại giao dịch dùng horizontally scrollable tabs hoặc 3 primary + “Khác”; validation inline; note multiline; review summary cho workflow phức tạp; keyboard numeric và formatter nhất quán.

## 5. Component và modal audit

### Component duplication

Các vai trò Card, Button, TextField, Background đang có nhiều implementation. Điều này khiến sửa theme không lan sang toàn app. V3 phải là API chuẩn; Glass/Premium/Vikram chỉ là adapter trong migration và không nhận feature mới.

### Dialog

Năm `AlertDialog` được dựng trực tiếp trong Dashboard, Goal, Settings và Family. Cần chuyển về dialog primitive chung để thống nhất radius, CTA order, safe area, focus và accessibility.

### Bottom sheet

11 call site đang có nhiều builder khác nhau. Cần contract chung:

- Header: title + optional subtitle + close.
- Scrollable body.
- Sticky footer.
- `isScrollControlled` khi có keyboard.
- Max-height 90%.
- Safe-area bottom.
- Unsaved-change guard.

### Destructive action

Delete cần confirm có tên đối tượng và hậu quả. Nếu soft-delete, snackbar có Undo. Không đặt delete icon 20–24dp trần cạnh edit icon trên list row.

## 6. Backlog đề xuất

### Sprint 1 — Foundation và accessibility

1. Khóa semantic tokens và cấm hard-coded brand color.
2. Hoàn thiện V3 Button, IconButton, Card, Input, Dialog, BottomSheet.
3. Sửa disabled/loading/error states.
4. Nâng touch target ≥48dp và caption ≥12sp.
5. Thêm global privacy mode.
6. Widget tests ở 320dp và 200% font scale.

### Sprint 2 — Core money flows

1. App shell/navigation naming.
2. Dashboard giảm gradient và thống nhất hierarchy.
3. Transaction row + filter semantics.
4. Add transaction responsive types và validation.
5. Wallet privacy/carousel/add actions.

### Sprint 3 — Planning modules

1. Budget semantic threshold và empty state.
2. Report empty/chart/accessibility.
3. Goal progress/forecast.
4. Loan safe actions và due status.
5. Category/Asset đồng bộ component.

### Sprint 4 — Account, family và polish

1. Profile đổi thành management hub.
2. Settings/Family/Notification modal migration.
3. AI surface thống nhất.
4. Offline/sync states.
5. Dark mode và visual regression toàn bộ.

## 7. Success metrics

- 0 mã màu brand trực tiếp trong feature mới/migrated.
- 100% target tương tác ≥48dp.
- Không overflow ở 320dp, font scale 200%.
- Tất cả modal dùng 2 primitive chuẩn.
- Tất cả money text đi qua privacy-aware component.
- Task thêm giao dịch phổ biến hoàn tất trong ≤30 giây, không lỗi validation mơ hồ.
- Budget/report empty state luôn có next action.
- Light/dark parity cho mọi màn hình đã migrate.

## 8. Đánh giá tổng thể

| Hạng mục | Điểm hiện tại | Nhận xét |
|---|---:|---|
| Information architecture | 6/10 | Core tabs tốt, module quản lý bị giấu trong Profile |
| Visual consistency | 4/10 | Nhiều palette và component system cùng tồn tại |
| Interaction clarity | 7/10 | Flow chính rõ, disabled/destructive còn yếu |
| Accessibility | 5/10 | Semantics có nền tảng, text/touch target chưa đạt |
| Responsive | 5/10 | Mobile ổn, font lớn/tablet cần làm lại |
| Data trust | 6/10 | Số liệu rõ, thiếu sync/offline/privacy toàn app |
| Modal consistency | 5/10 | Một số sheet tốt nhưng contract phân mảnh |
| Tổng thể | 5.4/10 | Nền tảng chức năng tốt; cần migration UI có kỷ luật |

Ưu tiên quan trọng nhất: không thiết kế thêm một “theme” mới. Hãy hoàn tất migration về một hệ V3 duy nhất, bắt đầu từ primitive và các luồng tiền cốt lõi.
