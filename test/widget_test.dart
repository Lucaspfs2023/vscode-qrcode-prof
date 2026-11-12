import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qrcode_prof/app/qrcode_prof_app.dart';

void main() {
  testWidgets('mostra a tela inicial do QRCODE PROF', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QRCodeProfApp()));
    expect(find.text('QRCODE PROF'), findsOneWidget);
    expect(find.text('Olá, professor!'), findsOneWidget);
  });
}
