# Integração Firebase / Cloud Firestore
## Alvo fornecido pelo usuário
- Projeto: gusta-nfcs.
- Database ID: ai-studio-conectordebanco-005a990b-ecd4-41ad-ba1e-0e68b83c29fd.
- App web: 1:28901594364:web:bfb7fe740ca8b71035b379.
- Auth domain: gusta-nfcs.firebaseapp.com.
- Storage bucket: gusta-nfcs.firebasestorage.app.
- Demais opções: config/firebase.local.json (local, ignorado no Git).
Firestore, não Realtime Database. Nunca usar FirebaseFirestore.instance (banco default) por engano. Na implementação futura usar FirebaseFirestore.instanceFor(app: app, databaseId: databaseId). Exigir databaseId não vazio no bootstrap.

## O que já foi feito
Somente configuração local e instruções. Não foram instalados pacotes Firebase no aplicativo, realizadas autenticações, acessados dados nem alteradas regras. O app permanece vazio.

## Sequência do Antigravity
1. Inspecionar versões de FlutterFire, compatibilidade e pubspec antes de adicionar firebase_core, firebase_auth, cloud_firestore, firebase_storage e demais pacotes necessários. Fixar resolução no lockfile.
2. Separar configuração de teste/emulador e produção. Não imprimir config completa. Config web é identificador público de cliente, não credencial Admin; jamais usar service-account ou segredo OAuth no app.
3. Inicialização web com FirebaseOptions mapeadas do arquivo local; firestoreDatabaseId e oAuthClientId não são argumentos arbitrários de FirebaseOptions. Database ID pertence a instanceFor. OAuth é aplicado no fluxo apropriado da plataforma, conforme documentação da versão instalada.
4. Config fornecida é WEB. Não reutilizar web appId no Android/iOS. Identificadores gerados com com.example.nfc_ops são provisórios. Confirmar identidade nativa antes de registrar apps remotos, obter google-services.json/GoogleService-Info.plist e SHA exigidos via FlutterFire/console.
5. Inspecionar ferramenta Firebase instalada; se faltar, verificar pacote oficial e instalar localmente para o projeto. Executar firebase login em sessão interativa, abrir navegador e AGUARDAR o usuário entrar. Não usar --reauth se sessão válida já existe.
6. Após login, confirmar projeto e banco por leitura. Não recriar banco nem cair em (default). Erro permission-denied não se resolve abrindo rules.
7. Fluxo Google DENTRO DO APP é separado: abrir popup/redirecionamento a partir do botão e aguardar usuário, sem automatizar senha/consentimento. Verificar users/{uid} no banco nomeado; documento inexistente é acesso negado. Provisionamento inicial de administrador exige ato privilegiado explícito do proprietário; nunca autoinscrição admin.
8. Testar leitura mínima autorizada e registrar apenas resultado, projeto/banco e timestamp. Redigir evidências sem dados pessoais nem tokens.
9. Escritas e testes negativos no emulador. Se for necessária escrita real de validação, apresentar coleção/documento/payload mínimo sintético e obter autorização; não tocar dados existentes.
10. Verificar provedores Google, domínios autorizados, regras, índices, Storage, Functions e região antes de usar. measurementId e recaptchaSiteKey vazios não significam habilitados. Não desabilitar App Check, não usar chave debug em produção.
11. Deploy de rules/índices/functions e Scheduler modifica infraestrutura remota: preparar e testar localmente; pedir aprovação concreta antes de aplicar.

## Pausa de autenticação
Registrar WAITING_USER_AUTH com superfície (CLI / app / console), ação pendente e como retomar, sem código/token/senha. Manter o login aberto enquanto válido; se expirar, informar e iniciar uma nova tentativa somente quando apropriado. Timeout nunca aprova login. Pode continuar trabalho local independente, mas integração permanece bloqueada.

## Fontes oficiais consultadas em 20/09/2026
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/FirebaseFirestore/instanceFor.html
