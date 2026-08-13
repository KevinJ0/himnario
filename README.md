# Himnario — Himnos de Gloria y Triunfo

Aplicación Flutter para consultar el himnario "Himnos de Gloria y Triunfo" (398 himnos). Pensada para dispositivos móviles y escritorio, con una interfaz elegante que combina tipografía clásica y moderna.

## Características

- **Índice alfabético** con sidebar A–Z, encabezados fijos y salto por letra al deslizar.
- **Búsqueda tolerante**: ignora tildes y encuentra coincidencias aunque escribas mal (normalización + distancia de Levenshtein por palabra).
- **Favoritos**: guarda himnos con un corazón desde cualquier lista; sección dedicada en la pestaña "Favoritos".
- **Himnos recientes**: los últimos himnos consultados aparecen en una franja rápida sobre la lista principal (máx. 20, persistente, borrable).
- **Tema claro/oscuro** con persistencia de preferencia entre sesiones.
- **Splash screen** con el icono de la app.
- Diseño responsive: lista o grid según el ancho disponible; detalle de himno con tipografía Garamond.

## Requisitos

- Flutter 3.x con soporte para Material 3.
- Dart 3.x.

## Cómo ejecutar

```sh
flutter pub get
flutter run
```

Para web:

```sh
flutter run -d chrome
```

## Estructura

```
lib/
  data/        Almacenes y controladores (favoritos, recientes, tema)
  models/      Modelos (Hymn)
  screens/     Splash, lista, detalle y pantalla principal
  theme/       Tema, paleta y fuentes
  widgets/     Componentes reutilizables
assets/
  himnos.json  Datos de los 398 himnos
  fonts/       Tipografías (EB Garamond, Inter)
test/          Tests de parseo, carga de datos y almacenes
```

## Pruebas

```sh
flutter test
```

## Licencia

El contenido de los himnos pertenece a sus respectivos autores. Uso personal y congregacional.
