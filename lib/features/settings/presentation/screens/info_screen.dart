import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/legal_links.dart';
import '../widgets/settings_bits.dart';

/// Info — **alles Nachschlagbare an einer Stelle**.
///
/// ## Warum eine Unterseite
///
/// Auf der Profilseite standen „Rechtliches" und „Über die App" als zwei
/// eigene Abschnitte, zusammen sieben Zeilen. Beides liest man einmal im
/// Leben; direkt über dem Konto-Bereich nahm es den Platz weg, den die
/// Einstellungen brauchen, die man tatsächlich ändert. Jetzt führt **eine**
/// Zeile hierher.
///
/// Die Versionsnummer bleibt draussen: Sie steht klein am Fuss der
/// Profilseite, weil sie beim Melden eines Fehlers gebraucht wird und dann
/// niemand erst eine Unterseite öffnen soll.
///
/// ## Rechtstexte öffnen in der App
///
/// Wie bisher (Board 08, A3/3): Custom Tab mit Zurück-Weg, keine fremde
/// Adressleiste. Langdruck öffnet extern. Scheitert das Öffnen, steht der
/// Hinweis oben auf **dieser** Seite — dort, wo der Tap war.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String? _notice;

  Future<void> _openLegal(Uri url, {bool external = false}) async {
    final l10n = AppL10n.of(context);
    final opened = await launchUrl(
      url,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) setState(() => _notice = l10n.legalError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.infoTitle, style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AtemSpacing.screenPadding, 0, AtemSpacing.screenPadding, 40),
          children: [
            const SizedBox(height: 4),
            AtemNoticeSlot(
              notice: _notice == null
                  ? null
                  : AtemNotice(
                      tone: AtemNoticeTone.error,
                      title: _notice!,
                      body: l10n.legalRetry,
                      semanticLabel: '$_notice. ${l10n.legalRetry}',
                    ),
            ),

            // ---- RECHTLICHES: in der App, Langdruck extern.
            SettingsSection(
              title: l10n.sectionLegal,
              children: [
                for (final (i, (label, url)) in [
                  (l10n.legalPrivacy, LegalLinks.privacy(language)),
                  (l10n.legalTerms, LegalLinks.terms(language)),
                  (l10n.legalImprint, LegalLinks.imprint),
                ].indexed) ...[
                  if (i > 0) const SettingsRule(),
                  SettingsRow(
                    label: label,
                    // **Unterzeile statt rechter Wert.** „In der App" ist
                    // eine Auskunft über den Weg, kein Messwert — rechts
                    // sprang sie bei „Nutzungsbedingungen" in eine zweite
                    // Zeile, während die Nachbarzeilen einzeilig blieben.
                    hint: l10n.legalInapp,
                    semanticLabel: '$label, ${l10n.legalInapp}',
                    onTap: () => _openLegal(url),
                    onLongPress: () => _openLegal(url, external: true),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AtemSpacing.md),

            // ---- ÜBER DIE APP: Tatsachen, keine Griffe. Ohne Version.
            SettingsSection(
              title: l10n.sectionAbout,
              children: [
                // Die Zeile steht dort, wo in der Vorgänger-App ein
                // Themenschalter war. Für ATEM existiert keine helle Palette;
                // eine Auskunft beantwortet die Frage, ein toter Schalter
                // nicht.
                SettingsFactRow(
                  label: l10n.aboutDisplayLabel,
                  value: l10n.aboutDisplayValue,
                ),
                SettingsFactRow(
                  label: l10n.aboutLanguagesLabel,
                  value: l10n.aboutLanguagesValue,
                ),
                SettingsFactRow(
                  label: l10n.aboutAccessLabel,
                  value: l10n.aboutAccessValue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
