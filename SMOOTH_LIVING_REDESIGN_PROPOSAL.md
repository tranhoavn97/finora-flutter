# FINORA — Đề xuất redesign "MƯỢT & SỐNG" (v2)

> Phản hồi người dùng: *"app giật lag và quá xấu, thiết kế lại cho mượt mà"* + *"biến linh vật thành 3D có chuyển động"*.
> Quy trình: duyệt proposal + preview trước, rồi mới sửa code Flutter (theo thống nhất từ trước).

## 1. Vì sao bản 1.0.25 giật lag (đã đo trong code)

- Khi `systemWideLiquidGlass = true`, **mọi card** (`FloatingGlassCard`) đều gắn một `BackdropFilter` blur sigma 20 (`premium_widgets.dart:888-920`).
- Màn Trang chủ xếp 6–10 card như vậy **đồng thời** + top bar blur 22 + dock blur 26 → mỗi khung hình GPU phải đọc lại texture nền và gaussian-blur 8–12 lần → khựng/giật trên máy thật.
- Nghịch lý: fill của card đã **đục 88–98%** (`glassOpacity 0.88`, gradient `*0.96..0.98`) nên gần như **không nhìn xuyên qua được** → blur tốn GPU mà hầu như không tạo khác biệt thị giác.
- Kết luận: blur per-card là chi phí chết. Bỏ nó, giữ bề mặt kính (gradient mờ + viền specular + glow) → nhìn gần như cũ nhưng chạy 60fps.

## 2. Thiết kế "Kính nhẹ" (mượt) — giữ chất Liquid Glass, bỏ chi phí chết

Nguyên tắc **2 tầng**:
- **Tầng A — kính thật (BackdropFilter)** chỉ dùng ở nơi thật sự trong suốt đè lên nội dung cuộn: **top bar, dock, bottom sheet, dialog**. Tối đa 2–3 lớp blur sống mỗi màn; cap sigma ≤ 16–18 (thay vì 22–26).
- **Tầng B — kính nhẹ (KHÔNG blur)** cho **toàn bộ card / list / hero**: gradient fill mờ + viền specular chéo topLeft→bottomRight + inner highlight + soft shadow + glow emerald. Nhìn vẫn "kính lỏng" nhưng chi phí ~0.
- Nền aurora **tĩnh** (đã làm ở 1.0.25), giảm còn 4–5 orb, alpha thấp → không repaint.
- Thêm công tắc tuỳ chọn *"Kính thật toàn app (nặng)"* trong Theme Studio cho ai muốn blur per-card; **mặc định TẮT**.
- Migration một lần `finora_smooth_glass_v2`: đặt cấu hình kính nhẹ đồng bộ cho máy đã nâng cấp (theo đúng cổng đã dùng ở v1: chỉ máy mang cờ legacy hoặc cài mới; không đụng tuỳ chỉnh riêng).

Kết quả kỳ vọng: Trang chủ từ ~8–12 lớp blur/frame → **2 lớp** (top bar + dock). Giữ nguyên mọi tính năng, chỉ đổi cách render bề mặt.

## 3. Linh vật Rồng ngọc 3D "sống"

Hiện trạng: `FinoraInteractive3DMascot` đã có (xoay phối cảnh + lò xo + bóng động) nhưng **chưa được dùng ở đâu**; linh vật đang hiển thị là PNG tĩnh.

Nâng cấp thành linh vật sống động, giữ **đúng tạo hình rồng ngọc** hiện có:
- **Lơ lửng + thở** mặc định bật (sin nhẹ, squash/stretch rất khẽ).
- **Nghiêng 3D tương tác**: kéo ngón tay → xoay phối cảnh; buông → nảy lò xo elastic về trục.
- **Parallax nhiều lớp**: glow nền, thân rồng, sparkle/đồng xu di chuyển lệch nhau theo góc nghiêng → chiều sâu thật.
- **Chớp mắt** định kỳ + **lóe sáng đồng xu** + **sparkle** hạt li ti.
- **Chạm** → nhún nảy + burst đồng xu + bong bóng thoại AI ("Cố lên!", "Tiết kiệm nhé!"…).
- Tất cả chỉ dùng `Transform`/`Opacity`/`CustomPaint` + `RepaintBoundary` → 60fps, không blur, không nặng.
- Tôn trọng `MediaQuery.disableAnimationsOf` (reduce motion → tĩnh).
- Tích hợp: hero Trang chủ, AI Advisor, modal giao dịch thành công, màn mục tiêu.

### Phương án "3D" để người dùng chọn
- **A. 2.5D tương tác (khuyến nghị)**: puppet nhiều lớp từ đúng ảnh rồng hiện có + nghiêng 3D + parallax + chớp mắt. Mượt, nhẹ, đúng linh vật, không phụ thuộc mới.
- **B. Video 3D AI lặp**: dùng VideoGen tạo clip 5s rồng bay/lắc lư/chớp mắt từ chính ảnh gốc, phát lặp trong app. Chuyển động "thật" nhất nhưng nền baked, thêm `video_player`, nặng hơn.
- **C. Mô hình GLB 3D thật**: dựng model 3D mới + render (flutter_scene/model-viewer). Xoay 360° thật nhưng **khó khớp đúng tạo hình rồng hiện tại**, nặng và rủi ro cao.

## 4. Phạm vi & an toàn
- Không đổi logic nghiệp vụ, provider, điều hướng, dữ liệu.
- Chỉ đổi: đường render card (bỏ blur per-card), cap blur topbar/dock/sheet, migration kính nhẹ, widget linh vật mới + tích hợp.
- Kiểm chứng: `flutter analyze` sạch + toàn bộ test pass + build APK 1.0.26 (Build 126) > 125 để cài đè.
- Nghiệm thu thị giác/độ mượt cần máy thật (không có ADB trong phiên) — sẽ ghi rõ trong handoff, không tuyên bố parity khi chưa chạy thật.
