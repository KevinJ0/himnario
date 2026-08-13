import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

class FontChoice {
  final String family;
  final String label;

  const FontChoice(this.family, this.label);
}

class FontGroup {
  final String name;
  final List<FontChoice> fonts;

  const FontGroup(this.name, this.fonts);
}

/// Catálogo de estilos de letra agrupados por tipo, con más de 50 opciones.
const List<FontGroup> kFontGroups = [
  FontGroup('Serifas', [
    FontChoice('Inter', 'Predeterminada (Inter)'),
    FontChoice('Playfair Display', 'Playfair Display'),
    FontChoice('Lora', 'Lora'),
    FontChoice('Merriweather', 'Merriweather'),
    FontChoice('Source Serif 4', 'Source Serif 4'),
    FontChoice('Crimson Pro', 'Crimson Pro'),
    FontChoice('EB Garamond', 'EB Garamond'),
    FontChoice('Cormorant Garamond', 'Cormorant Garamond'),
    FontChoice('PT Serif', 'PT Serif'),
    FontChoice('Vollkorn', 'Vollkorn'),
    FontChoice('Libre Baskerville', 'Libre Baskerville'),
    FontChoice('Noto Serif', 'Noto Serif'),
    FontChoice('Cardo', 'Cardo'),
    FontChoice('Gentium Book Plus', 'Gentium Book Plus'),
  ]),
  FontGroup('Sans serif', [
    FontChoice('Open Sans', 'Open Sans'),
    FontChoice('Roboto', 'Roboto'),
    FontChoice('Lato', 'Lato'),
    FontChoice('Montserrat', 'Montserrat'),
    FontChoice('Poppins', 'Poppins'),
    FontChoice('Work Sans', 'Work Sans'),
    FontChoice('Nunito', 'Nunito'),
    FontChoice('Quicksand', 'Quicksand'),
    FontChoice('Raleway', 'Raleway'),
    FontChoice('Rubik', 'Rubik'),
    FontChoice('DM Sans', 'DM Sans'),
    FontChoice('Jost', 'Jost'),
    FontChoice('Source Sans 3', 'Source Sans 3'),
    FontChoice('Urbanist', 'Urbanist'),
  ]),
  FontGroup('Decorativas', [
    FontChoice('Abril Fatface', 'Abril Fatface'),
    FontChoice('Alfa Slab One', 'Alfa Slab One'),
    FontChoice('Anton', 'Anton'),
    FontChoice('Bebas Neue', 'Bebas Neue'),
    FontChoice('Bungee', 'Bungee'),
    FontChoice('Cinzel', 'Cinzel'),
    FontChoice('Fjalla One', 'Fjalla One'),
    FontChoice('Limelight', 'Limelight'),
    FontChoice('Oswald', 'Oswald'),
    FontChoice('Righteous', 'Righteous'),
    FontChoice('Suez One', 'Suez One'),
  ]),
  FontGroup('Manuscrita (cursiva)', [
    FontChoice('Allura', 'Allura'),
    FontChoice('Caveat', 'Caveat'),
    FontChoice('Dancing Script', 'Dancing Script'),
    FontChoice('Great Vibes', 'Great Vibes'),
    FontChoice('Pacifico', 'Pacifico'),
    FontChoice('Parisienne', 'Parisienne'),
    FontChoice('Satisfy', 'Satisfy'),
    FontChoice('Shadows Into Light', 'Shadows Into Light'),
    FontChoice('Yellowtail', 'Yellowtail'),
  ]),
  FontGroup('Monoespaciada', [
    FontChoice('Fira Mono', 'Fira Mono'),
    FontChoice('IBM Plex Mono', 'IBM Plex Mono'),
    FontChoice('JetBrains Mono', 'JetBrains Mono'),
    FontChoice('Roboto Mono', 'Roboto Mono'),
    FontChoice('Space Mono', 'Space Mono'),
  ]),
];

int get kFontTotalCount =>
    kFontGroups.fold(0, (sum, group) => sum + group.fonts.length);

/// Aplica la familia elegida a un [TextStyle]. Las dos fuentes empaquetadas
/// (Inter y Playfair Display) se usan de su asset local; el resto se resuelve
/// con Google Fonts (descarga y cachea la primera vez).
TextStyle applyFontFamily(TextStyle style, String family) {
  switch (family) {
    case 'Inter':
      return style.copyWith(fontFamily: AppFonts.body);
    case 'Playfair Display':
      return style.copyWith(fontFamily: AppFonts.display);
    default:
      return GoogleFonts.getFont(family, textStyle: style);
  }
}