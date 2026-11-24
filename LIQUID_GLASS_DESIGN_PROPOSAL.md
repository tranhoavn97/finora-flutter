# FINORA Liquid Glass — Đề xuất thiết kế (ĐÃ DUYỆT — đang triển khai)

Trạng thái: **Đã duyệt 2026-11-12.** Quyết định của người dùng:
1. Cường độ kính: **Toàn app** (blur thật rộng rãi; vẫn giữ lớp bảo vệ hiệu năng có sẵn).
2. Nền aurora: **Trôi chậm, tự tắt** khi hệ thống bật giảm chuyển động.
3. Dark mode: **Giữ obsidian** hiện tại + quầng sáng nhẹ.
4. Palette: **Giữ emerald** (zero-purple guarantee).

Cách triển khai thực tế: tận dụng hạ tầng Liquid Glass có sẵn của `ThemeStudioController`
(`systemWideLiquidGlass`, `LiquidSpecularBorderPainter`, `LiquidRefractionPainter`) thay vì xây
song song — bật mặc định, thêm lớp aurora trôi chậm và đánh bóng viền specular chéo.
Phạm vi: `D:\FINORA-\flutter` — giữ nguyên 100% logic, dữ liệu, điều hướng và hành vi hiện có.

## 1. Tầm nhìn

Mang ngôn ngữ **Liquid Glass** (Apple 2025) vào FINORA nhưng giữ chất "tài chính đáng tin cậy":
thuỷ tinh phản chiếu có độ sâu, viền sáng đặc trưng (specular), nền aurora chuyển động chậm,
chuyển động lỏng mượt — trong khi **số tiền luôn đọc rõ ngay lập tức**, và mọi hiệu ứng
đều có bản "tĩnh" cho máy yếu / `disableAnimations`.

Không đổi: thương hiệu emerald (zero-purple guarantee), ngữ nghĩa màu Vợ/Chồng/Chung,
hệ thống token V8, cấu trúc màn hình, state management, Firestore sync.

## 2. 4 nguyên tắc thiết kế

1. **Specular Edge (viền khúc xạ)** — mọi tấm kính có viền gradient: sáng rực góc trên-trái
   (như ánh sáng đi qua mép kính), mờ dần về góc dưới-phải. Đây là chữ ký của Liquid Glass.
2. **Refractive Depth (độ sâu khúc xạ)** — kính mờ thật (`BackdropFilter`) chỉ dùng ở lớp nổi:
   thanh điều hướng, top bar, bottom sheet, hero card. Nội dung phía sau bị "uốn cong" nhẹ qua lớp mờ.
3. **Liquid Aurora (nền aurora lỏng)** — 3 quầng sáng radial (emerald / teal / mint) trôi rất chậm
   (chu kỳ 24–32s) phía sau kính, tạo cảm giác chất lỏng chảy. Tắt hoàn toàn khi `disableAnimations`.
4. **Quiet Motion (chuyển động tĩnh lặng)** — sheet bật bằng spring có độ nảy nhẹ, tab indicator
   trượt như giọt nước, ripple loang tròn. Không có hiệu ứng nào kéo dài quá 480ms.

## 3. Token mới (lớp `FinoraLiquidGlass`, bổ sung — không sửa V8)

### 3.1 Màu kính (dùng `withValues(alpha:)` trên nền trắng)

| Token | Light | Dark | Vai trò |
|---|---|---|---|
| `glassFill` | white 0.55 | white 0.07 | thân kính mờ (nav, top bar, sheet) |
| `glassFillStrong` | white 0.70 | white 0.11 | hero card, panel quan trọng |
| `glassFillFaint` | white 0.38 | white 0.05 | chip, pill phụ |
| `glassSpecular` | white 0.85 | white 0.18 | viền sáng góc trên-trái |
| `glassEdge` | white 0.30 | white 0.07 | viền mờ góc dưới-phải |
| `glassInnerGlow` | white 0.40 | white 0.08 | quầng sáng bên trong mép trên |
| `glassShadow` | đen 0.10 | đen 0.45 | đổ bóng dịu 24dp |

### 3.2 Aurora (nền, alpha rất thấp — không át nội dung)

| Token | Light | Dark |
|---|---|---|
| `auroraA` (mint) | `#34D399` @ 0.20 | `#34D399` @ 0.16 |
| `auroraB` (teal) | `#0D9488` @ 0.14 | `#0D9488` @ 0.14 |
| `auroraC` (sky) | `#38BDF8` @ 0.12 | `#38BDF8` @ 0.10 |

### 3.3 Blur & radius

- Blur: `strong 28dp` (hero), `soft 20dp` (nav/sheet), `faint 12dp` (top bar).
- Radius: hero `28dp`, card `24dp`, input `16dp`, nav pill `999dp`, sheet top `32dp`.
- Viền: 1dp gradient (specular → edge), không dùng border đặc.

### 3.4 Motion

- `liquidSpring` (slightly overshoot, 420ms) cho sheet/hero; `liquidSlide` (280ms) cho tab indicator;
  press 100ms, ripple radius 44dp. Haptic giữ nguyên chuẩn V8. `disableAnimations` → 0ms.

## 4. Component mới (file mới trong `core/design_system/v9_liquid/`)

| Component | Mô tả | Blur thật? |
|---|---|---|
| `LiquidGlassPanel` | tấm kính chuẩn: fill + viền specular + inner glow + bóng dịu; tham số `blur: none/faint/soft/strong` | tuỳ chọn |
| `LiquidAurora` | `CustomPainter` 3 quầng radial trôi chậm; dùng làm nền `GlassScaffold` | — |
| `LiquidNavBar` | thanh điều hướng nổi dạng pill kính, nút + gradient ở giữa | soft (cache) |
| `LiquidTopBar` | kính xuất hiện khi cuộn (wrap `GlassTopBar`, giữ nguyên API) | faint (cache) |
| `LiquidButton` | nút kính có viền specular + highlight; filled/tonal/ghost | — |
| `LiquidSheet` | bottom sheet kính với tay kéo, spring bật | soft (cache) |
| `LiquidChip` | chip chọn dạng kính, selected = fill + viền brand | — |

## 5. Chiến lược hiệu năng (bắt buộc trên Android)

- **Kính thật chỉ ở lớp nổi**: nav, top bar, sheet, hero — mỗi nơi 1 `BackdropFilter` duy nhất,
  bọc `RepaintBoundary`, blur giá trị cố định (không animate blur).
- **Danh sách dài dùng "faux glass"**: fill gradient mờ + viền specular + inner glow, **không blur**.
  Đặt trên nền aurora tĩnh (hoặc tĩnh hoá aurora khi cuộn), thị giác gần như tương đương.
- **Aurora**: 1 painter duy nhất toàn màn hình, chỉ vẽ khi frame cần (`RepaintBoundary` + `vsync` chậm),
  tắt khi `disableAnimations` hoặc `performanceOverlay` phát hiện jank.
- Chạy lại toàn bộ test sau mỗi pha; đặc biệt Milestone 1 Adversarial Stress (288px + 1.6x scale) và E2E 4 tầng.

## 6. Kế hoạch migration (3 pha, mỗi pha xanh analyze + 286 tests)

- **Pha 1 — Nền tảng (file mới, zero rủi ro)**: `v9_liquid/` tokens + `LiquidAurora` + `LiquidGlassPanel`
  + `LiquidButton` + `LiquidChip`. Chưa màn hình nào dùng.
- **Pha 2 — Shell & lớp nổi**: đổi nền `GlassScaffold` sang aurora (kèm công tắc bật/tắt),
  nâng cấp `GlassTopBar`, `FinoraNavigation` → pill kính nổi, sheet → `LiquidSheet`.
  Tương thích ngược: API giữ nguyên, các trang cũ không cần sửa.
- **Pha 3 — Màn hình trọng điểm**: Dashboard hero, thẻ ví WealthHub, quick actions,
  giao dịch (faux glass rows), báo cáo, trang thêm giao dịch. Từng màn hình một, verify bằng test + chụp ảnh.

## 7. Quyết định cần duyệt

1. **Cường độ kính**: toàn app vs tập trung (hero/nav/sheet + faux glass cho list) — *khuyến nghị: tập trung* (vì hiệu năng).
2. **Nền aurora**: có chuyển động chậm hay tĩnh — *khuyến nghị: chuyển động chậm, tắt được*.
3. **Dark mode**: giữ obsidian hiện tại + aurora phát sáng nhẹ — *khuyến nghị: giữ*.
4. **Palette**: giữ emerald brand hiện tại (không đổi sang xanh dương/tím).
