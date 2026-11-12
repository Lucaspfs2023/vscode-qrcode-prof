# QRCODE PROF

Base inicial do aplicativo multiplataforma.

## Requisitos
- Flutter SDK instalado
- Chrome para teste inicial
- Android Studio e Android SDK para testes Android

## Executar no Windows
Abra esta pasta no VS Code. No terminal, confirme que está na pasta que contém `pubspec.yaml` e execute:

```powershell
flutter pub get
flutter run -d chrome
```

Para gerar/atualizar as pastas nativas Android e iOS:

```powershell
flutter create . --platforms=android,ios,web
```

Depois execute novamente `flutter pub get`.

Observação: a compilação e publicação para iOS exigem macOS com Xcode.

## Histórico de correções

Na tela de correção, use **Salvar correção** no resultado da prova correspondente para registrar a tentativa localmente. Cartões gerados pelo app incluem aluno e turma no QRCode; códigos sem esses dados continuam corrigíveis, mas ficam identificados como não identificados nos indicadores. O painel administrativo e suas exportações PDF/CSV usam apenas correções salvas, não estimativas.

## Backup e restauração

No painel administrativo, abra **Backup e restauração** e exporte o arquivo JSON para salvar turmas, alunos, provas, questões e histórico de correções. Guarde uma cópia fora do dispositivo: os dados do aplicativo são locais e não são sincronizados automaticamente.

Para restaurar, abra um backup JSON, copie o conteúdo e cole no campo da mesma janela. A restauração substitui todos esses dados locais; exporte o estado atual antes de confirmar. São aceitos backups do esquema `qrcode-prof-local-backup`, versão 1.
