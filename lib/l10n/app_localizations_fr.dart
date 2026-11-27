// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Télécommande Smart TV';

  @override
  String get selectDevice => 'Choisir un appareil';

  @override
  String get addManually => 'Ajouter manuellement';

  @override
  String get addTvManually => 'Ajouter un téléviseur manuellement';

  @override
  String get tvIpAddress => 'Adresse IP du téléviseur';

  @override
  String get nameOptional => 'Nom (facultatif)';

  @override
  String get cancel => 'Annuler';

  @override
  String get add => 'Ajouter';

  @override
  String get scanning => 'Recherche sur le réseau…';

  @override
  String get devicesFound => 'Appareils trouvés';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils trouvés',
      one: '$count appareil trouvé',
      zero: 'Aucun appareil trouvé',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Aucun appareil trouvé';

  @override
  String get noDevicesHint =>
      'Vérifiez que votre téléviseur est allumé\net sur le même réseau Wi-Fi';

  @override
  String get discoveryFailed => 'Échec de la recherche';

  @override
  String get scanAgain => 'Relancer la recherche';

  @override
  String get noWifi => 'Pas de connexion Wi-Fi';

  @override
  String get noWifiHint =>
      'Connectez-vous à un réseau Wi-Fi pour que l\'application puisse joindre votre téléviseur.';

  @override
  String get wifiReconnected => 'Wi-Fi reconnecté';

  @override
  String get wifiDisconnected => 'Wi-Fi déconnecté — vérifiez votre connexion';

  @override
  String get remote => 'Télécommande';

  @override
  String get reconnect => 'Reconnecter';

  @override
  String get numericKeypad => 'Clavier numérique';

  @override
  String get power => 'Alimentation';

  @override
  String get connecting => 'Connexion…';

  @override
  String get reconnecting => 'Reconnexion…';

  @override
  String get connected => 'Connecté';

  @override
  String get connectionError => 'Erreur de connexion';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String get idle => 'Inactif';

  @override
  String disconnectedReason(String reason) {
    return 'Déconnecté : $reason';
  }

  @override
  String get ok => 'OK';

  @override
  String get back => 'Retour';

  @override
  String get exit => 'Quitter';

  @override
  String get smart => 'Smart';

  @override
  String get input => 'Entrée';

  @override
  String get up => 'Haut';

  @override
  String get down => 'Bas';

  @override
  String get left => 'Gauche';

  @override
  String get right => 'Droite';

  @override
  String get volumeUp => 'Volume +';

  @override
  String get volumeDown => 'Volume −';

  @override
  String get mute => 'Sourdine';

  @override
  String get channelUp => 'Chaîne suivante';

  @override
  String get channelDown => 'Chaîne précédente';

  @override
  String get menu => 'Menu';

  @override
  String get more => 'Plus';

  @override
  String get rewind => 'Retour arrière';

  @override
  String get record => 'Enregistrer';

  @override
  String get play => 'Lecture';

  @override
  String get stop => 'Arrêt';

  @override
  String get pause => 'Pause';

  @override
  String get fastForward => 'Avance rapide';

  @override
  String get redButton => 'Bouton rouge';

  @override
  String get greenButton => 'Bouton vert';

  @override
  String get yellowButton => 'Bouton jaune';

  @override
  String get blueButton => 'Bouton bleu';

  @override
  String get invalidIpv4 => 'Adresse IPv4 invalide';

  @override
  String get enterIpAddress => 'Saisissez une adresse IP';

  @override
  String get lookingForTvs => 'Recherche de téléviseurs…';

  @override
  String get brand => 'Marque';

  @override
  String get brandSamsung => 'Samsung';

  @override
  String get brandLg => 'LG';

  @override
  String ipLabel(String host) {
    return 'IP : $host';
  }

  @override
  String macLabel(String mac) {
    return 'MAC : $mac';
  }

  @override
  String get smartHub => 'Hub Smart';

  @override
  String get inputSource => 'Source d\'entrée';

  @override
  String get unknown => 'inconnu';

  @override
  String get manualIpHint => '192.168.1.42';

  @override
  String get manualNameHint => 'TV du salon';

  @override
  String get forgetTv => 'Oublier ce téléviseur';

  @override
  String forgetTvConfirm(String name) {
    return 'Supprimer $name et son appairage ? Vous devrez autoriser l\'application sur le téléviseur à nouveau.';
  }

  @override
  String get forget => 'Oublier';

  @override
  String connectionFailed(String reason) {
    return 'Connexion impossible : $reason';
  }
}
