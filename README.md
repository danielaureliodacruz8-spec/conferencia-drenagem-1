# Conferência de Drenagem

Projeto Flutter para Android e iOS, preparado para testes de campo de fiscalização de drenagem rodoviária.

## Gerar para iPhone pelo CodeMagic

O CodeMagic compila o aplicativo em um Mac na nuvem. Assim, você pode iniciar a compilação pelo Safari no iPhone, sem precisar usar um computador Mac.

O arquivo `codemagic.yaml` contém dois workflows iOS, ambos configurados para **Xcode 27.2**:

### 1. `ios-device-check` — validar se o app compila

- Gera a estrutura iOS.
- Define o nome exibido como **Conferência de Drenagem**.
- Configura as permissões de localização, câmera e galeria.
- Compila sem assinatura e entrega um ZIP com o app iOS.
- **O ZIP sem assinatura não pode ser instalado em um iPhone real.** Ele serve para validar a compilação.

### 2. `ios-iphone-development` — gerar IPA para instalar no iPhone

Antes de executar:

1. Tenha uma associação ativa ao Apple Developer Program.
2. Registre o UDID do iPhone na conta Apple Developer.
3. Disponibilize um certificado **Apple Development** e um perfil **iOS App Development** para o identificador:
   `br.com.stratabasitec.conferenciadrenagem`
4. No CodeMagic, abra **Team settings → codemagic.yaml settings → Code signing identities**.
5. Envie o certificado `.p12` e o perfil `.mobileprovision`.
6. Execute o workflow `ios-iphone-development`.

O arquivo esperado em **Artifacts** é `build/ios/ipa/*.ipa`. O perfil de desenvolvimento precisa incluir o iPhone usado no teste.

**Importante:** aceitar o contrato gratuito da Apple, sozinho, não fornece os certificados e perfis necessários para esse fluxo de assinatura. A compilação sem assinatura também não substitui a assinatura para instalação em aparelho real.

## Gerar APK Android

O workflow `android-debug` continua disponível e separado dos workflows iOS. Ele gera o APK de teste Android como antes.

## Identificação do aplicativo

- Nome exibido: **Conferência de Drenagem**
- Bundle identifier iOS: `br.com.stratabasitec.conferenciadrenagem`
- Versão: `0.1.1+2`

O identificador iOS deste repositório é diferente do usado no repositório **Conferência de Drenagem 2**, permitindo que os dois aplicativos sejam reconhecidos separadamente no iPhone.

## Funções e dados preservados

- Código principal em `lib/main.dart`.
- Seleção de GO-110 e GO-236.
- Cálculo estimado de estaca pelo eixo e localização GPS.
- Registro de coordenadas, medidas, observações e fotos.
- Armazenamento local.
- Dados de referência, alinhamentos, catálogos e imagens em `material-base/`.

Nenhuma função Dart do aplicativo foi alterada nesta preparação para iOS.
