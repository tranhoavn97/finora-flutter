import 'package:flutter_test/flutter_test.dart';
import 'package:finora/core/utils/vietqr_parser.dart';

void main() {
  group('VietQrParser Tests', () {
    test('Parses standard static VietQR for Vietcombank correctly', () {
      const vcbPayload =
          '00020101021138540010A00000072701240006970436011001234567890208QRIBFTTA53037045802VN6304ABCD';

      final data = VietQrParser.parse(vcbPayload);
      expect(data, isNotNull);
      expect(data!.bankBin, equals('970436'));
      expect(data.bankShortName, equals('VCB'));
      expect(data.bankName, equals('Vietcombank'));
      expect(data.accountNumber, equals('0123456789'));
      expect(data.hasFixedAmount, isFalse);
      expect(data.amount, isNull);
      expect(data.androidPackage, equals('com.VCB'));
      expect(data.iosScheme, equals('vcb://'));
    });

    test('Parses dynamic VietQR with Amount and Memo for MB Bank correctly', () {
      const mbDynamicPayload =
          '00020101021238540010A00000072701240006970422011088889999000208QRIBFTTA530370454061500005802VN62080804Cafe6304BEEF';

      final data = VietQrParser.parse(mbDynamicPayload);
      expect(data, isNotNull);
      expect(data!.bankBin, equals('970422'));
      expect(data.bankShortName, equals('MB'));
      expect(data.accountNumber, equals('8888999900'));
      expect(data.hasFixedAmount, isTrue);
      expect(data.amount, equals(150000.0));
      expect(data.memo, equals('Cafe'));
      expect(data.androidPackage, equals('com.mbmobile'));
      expect(data.iosScheme, equals('mbmobile://'));
    });

    test('Parses Techcombank pipe-delimited format', () {
      const pipePayload = 'TCB|19034567890012|250000|Tien com';

      final data = VietQrParser.parse(pipePayload);
      expect(data, isNotNull);
      expect(data!.bankShortName, equals('TCB'));
      expect(data.accountNumber, equals('19034567890012'));
      expect(data.amount, equals(250000.0));
      expect(data.memo, equals('Tien com'));
    });

    test('Parses VietQR URL format correctly', () {
      const urlPayload =
          'https://api.vietqr.io/image/970407-1903999988-compact2.jpg?amount=75000&addInfo=TraSua';

      final data = VietQrParser.parse(urlPayload);
      expect(data, isNotNull);
      expect(data!.bankBin, equals('970407'));
      expect(data.bankShortName, equals('TCB'));
      expect(data.accountNumber, equals('1903999988'));
      expect(data.amount, equals(75000.0));
      expect(data.memo, equals('TraSua'));
    });

    test('Parses EMVCo VietQR with prefix and suffix padding', () {
      const paddedPayload =
          'PREFIX_TEXT_00020101021138540010A00000072701240006970436011001234567890208QRIBFTTA53037045802VN6304ABCD_EXTRA_SUFFIX';

      final data = VietQrParser.parse(paddedPayload);
      expect(data, isNotNull);
      expect(data!.bankBin, equals('970436'));
      expect(data.bankShortName, equals('VCB'));
      expect(data.accountNumber, equals('0123456789'));
    });

    test('Parses SePay URL format correctly', () {
      const sepayUrl =
          'https://qr.sepay.vn/img?bank=MB&acc=0987654321&template=compact&amount=50000&des=AnToi';

      final data = VietQrParser.parse(sepayUrl);
      expect(data, isNotNull);
      expect(data!.bankShortName, equals('MB'));
      expect(data.accountNumber, equals('0987654321'));
      expect(data.amount, equals(50000.0));
      expect(data.memo, equals('AnToi'));
    });

    test('Parses space-separated text format fallback', () {
      const textFormat = 'VCB 0123456789 250000 Tien An';

      final data = VietQrParser.parse(textFormat);
      expect(data, isNotNull);
      expect(data!.bankShortName, equals('VCB'));
      expect(data.accountNumber, equals('0123456789'));
      expect(data.amount, equals(250000.0));
      expect(data.memo, equals('Tien An'));
    });

    test('Returns null gracefully for invalid payload', () {
      expect(VietQrParser.parse(''), isNull);
      expect(VietQrParser.parse('hello world 123'), isNull);
    });
  });
}
