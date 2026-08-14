# Reglas ProGuard/R8 del proyecto Himnario.
#
# Flutter genera código AOT en Dart, así que el shrinking se centra en el
# código Java/Kotlin de la app y de los plugins. Estas reglas conservan el
# glue del engine y de los plugins, que R8 no puede analizar estáticamente.

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**
