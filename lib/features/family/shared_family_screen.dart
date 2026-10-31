import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/services/family_sharing_service.dart';

class SharedFamilyScreen extends StatefulWidget {
  final FamilySharingService? service;
  final Stream<String?>? userIds;
  const SharedFamilyScreen({super.key, this.service, this.userIds});
  @override
  State<SharedFamilyScreen> createState() => _SharedFamilyScreenState();
}

class _SharedFamilyScreenState extends State<SharedFamilyScreen>
    with WidgetsBindingObserver {
  late final FamilySharingService _service;
  final _email = TextEditingController();
  final _name = TextEditingController(text: 'Gia đình của tôi');
  Map<String, dynamic>? _state;
  List<Map<String, dynamic>> _transactions = [];
  String? _after, _error, _notice;
  String? _uid;
  bool _busy = false, _foreground = true;
  int _epoch = 0;
  Timer? _timer;
  StreamSubscription<String?>? _auth;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FamilySharingService();
    WidgetsBinding.instance.addObserver(this);
    if (widget.userIds == null) _uid = FirebaseAuth.instance.currentUser?.uid;
    _auth = (widget.userIds ??
            FirebaseAuth.instance.authStateChanges().map((user) => user?.uid))
        .listen((uid) {
      if (uid == _uid) return;
      _epoch++;
      if (!mounted) return;
      setState(() {
        _uid = uid;
        _state = null;
        _transactions = [];
        _after = null;
        _busy = false;
        _error = null;
        _notice = null;
      });
      _request();
    });
    _request();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_foreground) _request();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _request();
  }

  List<Map<String, dynamic>> _rows(String key) => (_state?[key] as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  Future<void> _request(
      [String action = 'state', Map<String, dynamic> args = const {}]) async {
    if (_busy || _uid == null) return;
    final uid = _uid, epoch = _epoch;
    bool current() => mounted && _uid == uid && _epoch == epoch;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await _service.request(action, args);
      if (!current()) return;
      setState(() {
        _state = next;
        _transactions = [];
        _after = null;
      });
      if (next['family'] != null) {
        final page = await _service.request('ledger');
        if (!current()) return;
        setState(() {
          _transactions = (page['transactions'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _after = page['nextAfter'] as String?;
        });
      }
      if (action != 'state' && current()) {
        setState(() =>
            _notice = 'Đã cập nhật trên máy chủ. Sổ riêng được giữ nguyên.');
      }
    } catch (e) {
      if (current()) {
        setState(() {
          _state = null;
          _transactions = [];
          _after = null;
          _error = FamilySharingService.errorText(e);
        });
      }
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _more() async {
    if (_busy || _after == null) return;
    final epoch = _epoch, uid = _uid;
    bool current() => mounted && epoch == _epoch && uid == _uid;
    setState(() => _busy = true);
    try {
      final page = await _service.request('ledger', {'after': _after});
      if (!current()) return;
      final keyed = {for (final tx in _transactions) tx['key']: tx};
      for (final tx in (page['transactions'] as List).cast<Map>()) {
        keyed[tx['key']] = Map<String, dynamic>.from(tx);
      }
      setState(() {
        _transactions = keyed.values.toList();
        _after = page['nextAfter'] as String?;
      });
    } catch (e) {
      if (current()) {
        setState(() {
          _state = null;
          _transactions = [];
          _after = null;
          _error = FamilySharingService.errorText(e);
        });
      }
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(
      String text, String action, Map<String, dynamic> args) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Xác nhận'),
              content: Text(text),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Xác nhận')),
              ],
            ));
    if (ok == true && mounted) await _request(action, args);
  }

  Widget _panel(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...children.map((w) =>
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: w)),
            ])),
      );
  Widget _button(String label, VoidCallback callback) =>
      FilledButton(onPressed: _busy ? null : callback, child: Text(label));
  String _money(dynamic value, [dynamic currency]) => NumberFormat.currency(
          locale: 'vi_VN',
          symbol: currency == null || currency == 'VND' ? '₫' : '$currency',
          decimalDigits: 0)
      .format(num.tryParse('$value') ?? 0);
  String _owner(dynamic uid) =>
      _rows('members')
          .where((m) => m['uid'] == uid)
          .map((m) => '${m['email']}')
          .firstOrNull ??
      '';

  @override
  Widget build(BuildContext context) {
    final family = _state?['family'] as Map?;
    final owner = family?['ownerUid'] == _uid;
    return GlassScaffold(
      appBar: GlassTopBar(title: 'Gia đình', actions: [
        IconButton(
            tooltip: 'Làm mới',
            onPressed: _busy ? null : () => _request(),
            icon: const Icon(Icons.refresh_rounded))
      ]),
      body: ListView(
          padding: EdgeInsets.fromLTRB(16, GlassScaffold.topInset(context), 16,
              MediaQuery.paddingOf(context).bottom + 24),
          children: [
            const Text(
                'Mỗi người một tài khoản. Chỉ chia sẻ ví được chọn; không sao chép hoặc cộng dữ liệu vào sổ riêng.'),
            const SizedBox(height: 8),
            const Text(
                'Quyền hiện tại: chỉ xem. Chủ ví ghi/sửa ở sổ riêng. Không chia sẻ tin ngân hàng gốc, ảnh hóa đơn hay giao dịch chuyển tiền. Cập nhật mỗi 15 giây khi trang đang mở.'),
            const SizedBox(height: 16),
            if (_uid == null) const Text('Đăng nhập để quản lý gia đình.'),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (_notice != null && _error == null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_notice!)),
            if (_state != null) ...[
              for (final i
                  in _rows('invitations').where((i) => i['incoming'] == true))
                _panel('Lời mời vào ${i['familyName']}', [
                  Text('Dành cho ${i['email']} · Hết hạn ${i['expiresAt']}'),
                  const Text('Nhận lời không tự chia sẻ dữ liệu cũ của bạn.'),
                  if (family == null)
                    _button('Tham gia',
                        () => _request('accept', {'invitationId': i['id']}))
                  else
                    const Text(
                        'Bạn cần rời nhóm hiện tại trước khi tham gia nhóm khác.'),
                  TextButton(
                      onPressed: _busy
                          ? null
                          : () =>
                              _request('decline', {'invitationId': i['id']}),
                      child: const Text('Từ chối')),
                ]),
              if (family == null)
                _panel('Chưa tham gia gia đình', [
                  const Text(
                      'Nếu vợ/chồng đã mời, hãy đăng nhập đúng email và bấm Làm mới. Chỉ tạo gia đình khi bạn muốn làm chủ nhóm.'),
                  TextField(
                      controller: _name,
                      maxLength: 100,
                      decoration:
                          const InputDecoration(labelText: 'Tên gia đình')),
                  _button('Tạo gia đình',
                      () => _request('create', {'name': _name.text.trim()})),
                ])
              else ...[
                _panel(
                    '${family['name']} · ${_rows('members').length}/10 người', [
                  for (final m in _rows('members'))
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${m['email']}'),
                        subtitle: Text(m['isOwner'] == true
                            ? 'Chủ nhóm'
                            : 'Thành viên · Chỉ xem ví được chia sẻ'),
                        trailing: owner && m['isOwner'] != true
                            ? IconButton(
                                tooltip: 'Xóa khỏi nhóm',
                                icon: const Icon(Icons.person_remove_outlined),
                                onPressed: _busy
                                    ? null
                                    : () => _confirm(
                                        'Thu hồi quyền xem dữ liệu chung của ${m['email']}?',
                                        'remove',
                                        {'uid': m['uid']}))
                            : null),
                  if (!owner || _rows('members').length == 1)
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => _confirm(
                                'Rời gia đình, ngừng chia sẻ ví và hủy lời mời đang chờ nếu bạn là chủ nhóm? Sổ riêng vẫn giữ nguyên.',
                                'leave', {}),
                        child: const Text('Rời gia đình')),
                ]),
                if (owner)
                  _panel('Mời vợ/chồng bằng email', [
                    TextField(
                        controller: _email,
                        maxLength: 254,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                            labelText: 'Email tài khoản của vợ/chồng')),
                    const Text(
                        'Lời mời xuất hiện ở mục Gia đình khi người nhận đăng nhập đúng email đã xác minh. Chưa gửi thư qua hộp thư email. Có hiệu lực 7 ngày.'),
                    _button(
                        'Tạo lời mời',
                        () => _request('invite',
                            {'email': _email.text.trim().toLowerCase()})),
                    for (final i in _rows('invitations')
                        .where((i) => i['incoming'] != true))
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${i['email']}'),
                          subtitle: const Text('Đang chờ'),
                          trailing: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _request(
                                      'revoke', {'invitationId': i['id']}),
                              child: const Text('Thu hồi'))),
                  ]),
                _panel('Chọn ví của bạn để chia sẻ', [
                  const Text(
                      'Bật ví sẽ chia sẻ tên, số dư và toàn bộ lịch sử thu/chi cùng ghi chú. Tắt để ngừng quyền xem từ lần tải tiếp theo.'),
                  if (_rows('myWallets').isEmpty)
                    const Text('Chưa có ví. Hãy thêm ví trong sổ riêng.'),
                  for (final w in _rows('myWallets'))
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${w['name'] ?? 'Ví chưa đặt tên'}'),
                        value: w['shared'] == true,
                        onChanged: _busy
                            ? null
                            : (value) => _request('share',
                                {'walletId': w['id'], 'shared': value})),
                ]),
                _panel('Ví đang chia sẻ · Chỉ xem', [
                  if (_rows('sharedWallets').isEmpty)
                    const Text('Chưa có ví được chia sẻ.'),
                  for (final w in _rows('sharedWallets'))
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '${w['name']} · ${w['balance'] == null ? 'Chưa đối soát số dư' : _money(w['balance'], w['currency'])}'),
                        subtitle: Text(_owner(w['ownerUid']))),
                ]),
                _panel('Giao dịch thu/chi được chia sẻ', [
                  if (_transactions.isEmpty)
                    const Text('Chưa có giao dịch thu/chi được chia sẻ.'),
                  for (final t in _transactions)
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '${t['note'] ?? t['category'] ?? 'Giao dịch'}'),
                        subtitle: Text(
                            '${_owner(t['ownerUid'])} · ${t['date'] ?? ''}'),
                        trailing: Text('${[
                          'income',
                          'interest_income'
                        ].contains('${t['type']}'.trim().toLowerCase()) ? '+' : '−'}${_money(t['amount'])}')),
                  if (_after != null) _button('Xem tiếp', _more),
                ]),
              ],
            ],
          ]),
    );
  }

  @override
  void dispose() {
    _epoch++;
    _timer?.cancel();
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service.close();
    _email.dispose();
    _name.dispose();
    super.dispose();
  }
}
