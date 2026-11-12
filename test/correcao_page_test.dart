import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_prof/features/correcao/correcao_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QR exam id selects only its matching proof', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CorrecaoPage(
          codigo: jsonEncode({
            'schema': 'qrcode-prof.card',
            'version': 2,
            'provaId': 'seed-av2-historia',
            'titulo': 'AV2 - História',
            'disciplina': 'História',
            'aluno': 'Davi Silva',
            'turma': '2º Ano B',
            'respostas': ['B', 'C', 'A', 'D', 'B'],
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resultado da prova selecionada'), findsOneWidget);
    expect(find.text('AV2 - História • História'), findsWidgets);
    expect(find.text('Acertos: 5'), findsOneWidget);
    expect(find.text('AV1 - Matemática'), findsNothing);
  });

  testWidgets('asks for proof and student identification when QR omits them',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CorrecaoPage(codigo: 'A,B,C,D,A')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vincular à prova'), findsOneWidget);
    expect(find.text('Confirmar identificação'), findsOneWidget);
    expect(
      find.textContaining('O QR não informa aluno ou turma.'),
      findsOneWidget,
    );
    expect(find.text('Salvar correção'), findsNothing);
  });
}
