with open('lib/features/settings/theme_studio_workspace.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _previewExpanded = true with false
code = code.replace('bool _previewExpanded = true;', 'bool _previewExpanded = false;')

# Replace Column with pinned preview with SingleChildScrollView
old_mobile = """                        : Column(
                            children: [
                              // 1. PINNED PREVIEW CONTAINER - LUÔN GHIM Ở ĐẦU TRANG
                              Material(
                                color: _surface.withValues(alpha: 0.98),
                                elevation: 3,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 6, 14, 8),
                                      child: _previewCard(),
                                    ),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: _muted.withValues(alpha: 0.12),
                                    ),
                                  ],
                                ),
                              ),
                              // 2. SCROLLABLE EDITOR / CATEGORIES BÊN DƯỚI
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _scroll,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 14, 16, 24),
                                  child: content,
                                ),
                              ),
                            ],
                          ),"""

new_mobile = """                        : SingleChildScrollView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: content,
                          ),"""

assert old_mobile in code, "old_mobile not found"
code = code.replace(old_mobile, new_mobile, 1)

# Clean up _previewCard title
old_title = """          title: Row(
            children: [
              Text('Xem trước',
                  style: TextStyle(
                      color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Ghim trực quan',
                    style: TextStyle(
                        color: widget.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          subtitle: Text('${widget.paletteName} • Chạm thành phần để sửa',
              style: TextStyle(color: _muted, fontSize: 11)),"""

new_title = """          title: Text('Xem trước',
              style: TextStyle(
                  color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text('${widget.paletteName} • Chạm thành phần để sửa',
              style: TextStyle(color: _muted, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),"""

assert old_title in code, "old_title not found"
code = code.replace(old_title, new_title, 1)

# didUpdateWidget
old_did_update = """    if (oldWidget.activeCategory != widget.activeCategory) {
      // Keep preview expanded so live editing remains immediately visible
      _scroll.jumpTo(0);
    }"""

new_did_update = """    if (oldWidget.activeCategory != widget.activeCategory) {
      _previewExpanded = false;
      _scroll.jumpTo(0);
    }"""

if old_did_update in code:
    code = code.replace(old_did_update, new_did_update, 1)

# ConstrainedBox around widget.preview in _previewCard
old_box = """        if (expanded)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.46,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: widget.preview,
            ),
          ),"""

new_box = """        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.preview,
          ),"""

if old_box in code:
    code = code.replace(old_box, new_box, 1)

with open('lib/features/settings/theme_studio_workspace.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print('Successfully patched theme_studio_workspace.dart!')
