import SwiftUI

enum LegalDocument: String, Identifiable {
  case privacy, terms
  var id: String { rawValue }
}

/// In-app privacy policy and terms. The same texts live in `legal/` for the web versions.
struct LegalView: View {
  var document: LegalDocument
  @Environment(StickStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        StickCreamBackground()
        ScrollView {
          Text(LegalTexts.text(for: document, language: store.profile.language))
            .font(StickFont.callout)
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(StickMetrics.screenMargin)
        }
      }
      .navigationTitle(document == .privacy ? Text("Privacy policy") : Text("Terms of use"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

enum LegalTexts {
  static let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

  static func text(for document: LegalDocument, language: AppLanguage) -> String {
    switch (document, language) {
    case (.privacy, .french): return privacyFR
    case (.privacy, .english): return privacyEN
    case (.terms, .french): return termsFR
    case (.terms, .english): return termsEN
    }
  }

  static let privacyEN = """
  Stick Privacy Policy
  Last updated: September 2026

  What Stick collects
  • Your first name, your identity sentence, your quiz answers, your call times and your daily goals. Stored on your phone.
  • One voice recording of about 60 seconds, made only after your explicit consent, used solely to create a private synthetic copy of your own voice.
  • Call transcripts (what you and Stick said), stored on your phone so you can reread them.
  • Optional 30-second "vault" message, stored on your phone only.
  • Screen Time data stays on your device: Apple never lets Stick see which apps you use.

  Third parties
  • Fish Audio (voice cloning and speech synthesis): receives your voice sample and the sentences Stick speaks. Your voice model is private and never published.
  • OpenRouter (language model): receives the text of the conversation, your first name, your goals and your identity sentence so Stick can answer you. No audio is sent.
  • Apple Speech Recognition: transcribes what you say during calls.
  • RevenueCat and Apple: handle purchases. Stick never sees your payment details.
  • Supabase: stores your account and league score (first name, hours recovered, days held). With Sign in with Apple, we receive the email Apple shares (or its private relay) and your first name; without an account, an anonymous id is used.

  Stick never sells data, never runs ads, never uses your voice for anyone but you.

  Your rights
  • Delete your voice clone at any time from Me › My voice.
  • Delete your account and all data from Me › Delete my account and data. This removes the anonymous account, the league row and every local file.
  • Contact: privacy@stick.app

  Children
  Stick is for people aged 16 and over.
  """

  static let privacyFR = """
  Politique de confidentialité de Stick
  Dernière mise à jour : septembre 2026

  Ce que Stick collecte
  • Ton prénom, ta phrase d'identité, tes réponses au questionnaire, tes horaires d'appel et tes objectifs du jour. Stockés sur ton téléphone.
  • Un enregistrement vocal d'environ 60 secondes, réalisé uniquement après ton consentement explicite, utilisé seulement pour créer une copie synthétique privée de ta propre voix.
  • Les transcriptions des appels (ce que Stick et toi avez dit), stockées sur ton téléphone pour que tu puisses les relire.
  • Le message « coffre » de 30 secondes, optionnel, stocké sur ton téléphone uniquement.
  • Les données Temps d'écran restent sur ton appareil : Apple ne laisse jamais Stick voir quelles apps tu utilises.

  Tiers
  • Fish Audio (clonage et synthèse vocale) : reçoit ton échantillon de voix et les phrases que Stick prononce. Ton modèle vocal est privé et jamais publié.
  • OpenRouter (modèle de langage) : reçoit le texte de la conversation, ton prénom, tes objectifs et ta phrase d'identité pour que Stick puisse te répondre. Aucun audio n'est envoyé.
  • Reconnaissance vocale Apple : transcrit ce que tu dis pendant les appels.
  • RevenueCat et Apple : gèrent les achats. Stick ne voit jamais tes données de paiement.
  • Supabase : stocke ton compte et ton score de ligue (prénom, heures récupérées, jours tenus). Avec « Se connecter avec Apple », nous recevons l'email partagé par Apple (ou son relais privé) et ton prénom ; sans compte, un identifiant anonyme est utilisé.

  Stick ne vend jamais de données, n'affiche jamais de publicité, n'utilise jamais ta voix pour quelqu'un d'autre que toi.

  Tes droits
  • Supprime ton clone vocal à tout moment depuis Moi › Ma voix.
  • Supprime ton compte et toutes tes données depuis Moi › Supprimer mon compte et mes données. Cela efface le compte anonyme, la ligne de ligue et tous les fichiers locaux.
  • Contact : privacy@stick.app

  Mineurs
  Stick s'adresse aux personnes de 16 ans et plus.
  """

  static let termsEN = """
  Stick Terms of Use
  Last updated: September 2026

  1. Stick is a digital-wellbeing coaching app. It is not a medical device and does not diagnose or treat any condition.
  2. Stick clones your own voice only. You confirm the voice you record is yours and you consent to its synthetic use inside Stick. Recording someone else's voice is forbidden.
  3. Purchases: the 75-Day Pass is a one-time purchase. Weekly and Stick Life are auto-renewable subscriptions billed to your Apple Account; they renew unless cancelled at least 24 hours before the end of the period. Manage them in Settings › Apple Account › Subscriptions. Refunds are handled by Apple.
  4. Free days offered through a referral link are a courtesy and can be withdrawn in case of abuse.
  5. The league displays your first name and score to other members. Choose a first name you are comfortable sharing.
  6. Stick's calls use a firm coaching tone by design. If it ever becomes distressing, stop using the app and delete your data from Me.
  7. Apple's standard licensed application end-user license agreement applies: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
  8. Contact: support@stick.app
  """

  static let termsFR = """
  Conditions d'utilisation de Stick
  Dernière mise à jour : septembre 2026

  1. Stick est une app de coaching et de bien-être numérique. Ce n'est pas un dispositif médical et elle ne diagnostique ni ne traite aucune condition.
  2. Stick clone uniquement ta propre voix. Tu confirmes que la voix enregistrée est la tienne et tu consens à son usage synthétique dans Stick. Enregistrer la voix d'une autre personne est interdit.
  3. Achats : le Pass 75 jours est un achat unique. Hebdo et Stick Life sont des abonnements renouvelés automatiquement, facturés sur ton compte Apple ; ils se renouvellent sauf annulation au moins 24 heures avant la fin de la période. Gère-les dans Réglages › Compte Apple › Abonnements. Les remboursements sont gérés par Apple.
  4. Les jours gratuits offerts via un lien de parrainage sont un geste commercial et peuvent être retirés en cas d'abus.
  5. La ligue affiche ton prénom et ton score aux autres membres. Choisis un prénom que tu acceptes de partager.
  6. Les appels de Stick adoptent volontairement un ton de coach ferme. Si cela devenait pénible, arrête d'utiliser l'app et supprime tes données depuis Moi.
  7. Le contrat de licence standard d'Apple s'applique : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
  8. Contact : support@stick.app
  """
}
