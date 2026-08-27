/// Wohin die rechtlichen Wege führen.
///
/// ## Warum im Browser und nicht in der App
///
/// Rechtstexte ändern sich, ohne dass jemand eine neue App-Fassung
/// installiert. Als Webseite ist die gezeigte Fassung immer die geltende;
/// eingebettet wäre sie die vom Tag der Veröffentlichung.
///
/// Dazu kommt eine Anforderung von Google Play: Die Datenschutzerklärung muss
/// unter einer öffentlichen Adresse erreichbar sein — sie existiert also
/// ohnehin als Webseite.
///
/// ## Noch nicht ausgerollt
///
/// Die Seiten liegen unter `web/legal/` und tragen neun Platzhalter für Name,
/// Anschrift und Kontaktadresse. Bis die gefüllt und die Seiten ausgerollt
/// sind, führen diese Adressen ins Leere — die Oberfläche meldet das dann als
/// Fehler, statt so zu tun, als hätte sie geöffnet.
abstract final class LegalLinks {
  static const _base = 'https://calisthenics-pro-57d6d.web.app/legal';

  /// Deutsch oder Englisch — die Seiten liegen in beiden Sprachen vor.
  static Uri privacy(String languageCode) => Uri.parse(
      '$_base/${languageCode == 'de' ? 'datenschutz' : 'privacy'}');

  static Uri terms(String languageCode) => Uri.parse(
      '$_base/${languageCode == 'de' ? 'nutzungsbedingungen' : 'terms'}');

  /// Das Impressum steht auf der Übersichtsseite; eine eigene Seite dafür
  /// gibt es nicht, weil die Angaben in beiden Sprachen dieselben sind.
  static Uri get imprint => Uri.parse('$_base/');
}
