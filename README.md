# Glimmer Grove

Match-3 luminoso para teléfonos y tabletas. Intercambia frutas vecinas, rompe la escarcha y convierte los movimientos sobrantes en ráfagas de luz. Cuatro en línea forman una raya, cinco un estallido solar y un ángulo un bombón de flor.

App Flutter. Los proyectos Android e iOS están en `android/` e `ios/`. El progreso, las monedas y los potenciadores se guardan en el dispositivo (`shared_preferences`). Id de aplicación Android: `com.glimmergrove.glimmer_grove`.

## Cómo jugar

1. Intercambia dos frutas vecinas para alinear tres o más del mismo tipo.
2. Cuatro en línea → **raya** (stripe). Cinco → **estallido solar** (sunburst). Ángulo en esquina → **bombón de flor** (bloom bomb).
3. Cumple los objetivos antes de que se acaben los movimientos. Los movimientos sobrantes se convierten en bonus de luz.
4. La fruta helada no se mueve hasta que un match vecino rompe el hielo.

## Contenido

- Tablero táctil con selección, intercambio, cascada, puntuación flotante, partículas y especiales encadenados.
- **24 niveles** en tres capítulos:
  - *Huerto soleado* — fruta cálida y brillo fácil
  - *Jardín lunapétulo* — la escarcha se cuela entre las flores
  - *Dosel aurora* — el bosque hondo guarda su fruta más viva
- Frutas: Bayasol, Ciruelarosa, Hojamenta, Perlaluna, Rocío, Higobrass.
- Pantallas: menú, mapa de niveles, partida (HUD), victoria/derrota, tienda, regalos diarios y ajustes.
- Potenciadores: **Mazo** (rompe una fruta), **Remover** (reordena el tablero), **+5 movimientos**.
- Tienda con monedas locales y cesta (3 mazos + 1 remolino). Regalo diario.
- Perfil con nombre y espíritu del huerto. Estrellas y mejor puntuación por nivel.

## Idioma

Sigue el idioma del dispositivo y se puede cambiar entre **English** y **Español** en Ajustes.

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK Dart `^3.13.5`)
- Dispositivo o emulador Android / iOS, o el target Linux incluido para revisar la UI en escritorio

## Ejecutar

```bash
flutter pub get
flutter run
```

APK de release:

```bash
flutter build apk
```

El paquete queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Tests

```bash
flutter test
```

Cubre detección de matches, hielo, gravedad, especiales, limpiezas arcoíris, umbrales de estrellas, layouts (390×844, 360×640, 844×390, 768×1024, 1440×900) y el campo de nombre del perfil.

## Estructura

```
lib/
  main.dart          # Arranque, orientación y tema
  theme.dart         # Paleta y tipografía
  audio/             # Efectos y música (audioplayers)
  game/              # Lógica match-3, sesión y definición de niveles
  l10n/              # Cadenas EN / ES
  paint/             # Arte vectorial del huerto, logo e iconos
  persist/           # Guardado local (monedas, estrellas, boosters)
  screens/           # Shell, menú, mapa, tienda, partida
  widgets/           # Controles compartidos
assets/
  fonts/             # Fredoka y Nunito (SIL Open Font License)
  sfx/               # Efectos de sonido
android/ ios/ linux/ # Targets nativos
test/                # Tests de lógica y widgets
```

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| `shared_preferences` | Progreso y ajustes en el dispositivo |
| `audioplayers` | SFX y música |
| `cupertino_icons` | Iconos iOS |

## Fuentes

Fredoka y Nunito están incluidas bajo la SIL Open Font License. Ver `assets/fonts/`.
