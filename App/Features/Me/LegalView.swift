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
          VStack(alignment: .leading, spacing: 20) {
            Text(LegalTexts.text(for: document, language: store.profile.language))
              .font(StickFont.callout)
              .foregroundStyle(Color.ink)
              .frame(maxWidth: .infinity, alignment: .leading)
            if document == .terms {
              Link(destination: AppLinks.appleEULA) {
                Label("Apple Standard EULA", systemImage: "arrow.up.right.square")
                  .font(StickFont.headline)
                  .foregroundStyle(Color.brandOrange)
              }
            }
          }
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

/// Same texts as `legal/*.md` and the website. Keep all three in sync.
enum LegalTexts {
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

  Stick has no server and no account database. Your program lives on your iPhone.

  What stays on your iPhone
  • Your first name, identity sentence, quiz answers, call times, daily goals and progress.
  • Call transcripts (what you and Stick said), so you can reread them.
  • Your voice sample and the optional 30-second "vault" message.

  What leaves your iPhone, and to whom
  • Fish Audio (voice cloning and speech synthesis), only after your explicit consent: your voice sample, to build a private synthetic copy of your own voice, and the sentences Stick speaks. Your voice model is private and never published.
  • OpenRouter (AI language model), only if you turn on smart replies: the text of what you say during calls, your first name, goals and identity sentence, so Stick can understand and answer you. No audio is sent. You can turn it off in Me › My voice; calls then follow a fixed script.
  • Apple Speech Recognition: transcribes what you say during calls. Apple may process audio on its servers under Apple's privacy policy.
  • Apple and RevenueCat: handle purchases. Stick never sees your payment details. If you sign in with Apple, RevenueCat receives the anonymous Apple identifier so your purchases follow you. RevenueCat also receives your progress in the program (day and act) and whether calls use your cloned voice, so Stick can show you the right offer. Never your name, goals or quiz answers.

  Sign in with Apple
  Optional. Stick asks Apple for no name and no email. Only an anonymous identifier is kept, in your iPhone's keychain.

  Stick never sells data, never shows ads, never tracks you across apps, and never uses your voice for anyone but you.

  Your rights and choices
  • Delete your voice clone at any time from Me › My voice (deleted at Fish Audio and on your iPhone).
  • Delete everything from Me › Delete my account and data.
  • Contact: \(AppLinks.contactEmail)

  Age
  Stick is for people aged 16 and over.
  """

  static let privacyFR = """
  Politique de confidentialité de Stick
  Dernière mise à jour : septembre 2026

  Stick n'a ni serveur ni base de comptes. Ton programme vit sur ton iPhone.

  Ce qui reste sur ton iPhone
  • Ton prénom, ta phrase d'identité, tes réponses au questionnaire, tes horaires d'appel, tes objectifs et ta progression.
  • Les transcriptions des appels (ce que Stick et toi avez dit), pour que tu puisses les relire.
  • Ton échantillon de voix et le message « coffre » de 30 secondes, optionnel.

  Ce qui quitte ton iPhone, et vers qui
  • Fish Audio (clonage et synthèse vocale), uniquement après ton consentement explicite : ton échantillon de voix, pour créer une copie synthétique privée de ta propre voix, et les phrases que Stick prononce. Ton modèle vocal est privé et jamais publié.
  • OpenRouter (modèle de langage IA), uniquement si tu actives les réponses intelligentes : le texte de ce que tu dis pendant les appels, ton prénom, tes objectifs et ta phrase d'identité, pour que Stick te comprenne et te réponde. Aucun audio n'est envoyé. Tu peux le désactiver dans Moi › Ma voix ; les appels suivent alors un script fixe.
  • Reconnaissance vocale Apple : transcrit ce que tu dis pendant les appels. Apple peut traiter l'audio sur ses serveurs selon sa propre politique de confidentialité.
  • Apple et RevenueCat : gèrent les achats. Stick ne voit jamais tes données de paiement. Si tu te connectes avec Apple, RevenueCat reçoit l'identifiant Apple anonyme pour que tes achats te suivent. RevenueCat reçoit aussi ta progression dans le programme (jour et acte) et si les appels utilisent ta voix clonée, pour te proposer la bonne offre. Jamais ton prénom, tes objectifs ni tes réponses au quiz.

  Se connecter avec Apple
  Optionnel. Stick ne demande à Apple ni ton nom ni ton email. Seul un identifiant anonyme est conservé, dans le trousseau de ton iPhone.

  Stick ne vend jamais de données, n'affiche aucune publicité, ne te suit pas d'une app à l'autre et n'utilise jamais ta voix pour quelqu'un d'autre que toi.

  Tes droits et tes choix
  • Supprime ton clone vocal à tout moment depuis Moi › Ma voix (supprimé chez Fish Audio et sur ton iPhone).
  • Supprime tout depuis Moi › Supprimer mon compte et mes données.
  • Contact : \(AppLinks.contactEmail)

  Âge
  Stick s'adresse aux personnes de 16 ans et plus.
  """

  static let termsEN = """
  Stick Terms of Use
  Last updated: September 2026

  1. Stick is a digital-wellbeing coaching app. It is not a medical device and does not diagnose or treat any condition.
  2. Stick clones your own voice only. You confirm the voice you record is yours and you consent to its synthetic use inside Stick. Recording or cloning someone else's voice is forbidden.
  3. Purchases: the 75-Day Pass is a one-time purchase that unlocks the full 75-day program; it does not renew. Weekly is an auto-renewable subscription billed to your Apple Account at confirmation and every week; it renews unless cancelled at least 24 hours before the end of the period. Manage it in Settings › Apple Account › Subscriptions. Refunds are handled by Apple.
  4. Stick's calls use a firm coaching tone by design. If it ever becomes distressing, stop using the app and delete your data from Me.
  5. Replies generated by the AI language model may be inaccurate. Stick is not professional advice.
  6. Apple's Standard Licensed Application End User License Agreement (EULA) applies to your use of Stick: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
  7. Contact: \(AppLinks.contactEmail)
  """

  static let termsFR = """
  Conditions d'utilisation de Stick
  Dernière mise à jour : septembre 2026

  1. Stick est une app de coaching et de bien-être numérique. Ce n'est pas un dispositif médical et elle ne diagnostique ni ne traite aucune condition.
  2. Stick clone uniquement ta propre voix. Tu confirmes que la voix enregistrée est la tienne et tu consens à son usage synthétique dans Stick. Enregistrer ou cloner la voix d'une autre personne est interdit.
  3. Achats : le Pass 75 jours est un achat unique qui débloque tout le programme de 75 jours ; il ne se renouvelle pas. Hebdo est un abonnement renouvelé automatiquement, facturé sur ton compte Apple à la confirmation puis chaque semaine ; il se renouvelle sauf annulation au moins 24 heures avant la fin de la période. Gère-le dans Réglages › Compte Apple › Abonnements. Les remboursements sont gérés par Apple.
  4. Les appels de Stick adoptent volontairement un ton de coach ferme. Si cela devenait pénible, arrête d'utiliser l'app et supprime tes données depuis Moi.
  5. Les réponses générées par le modèle de langage IA peuvent être inexactes. Stick n'est pas un conseil professionnel.
  6. Le contrat de licence standard d'Apple (EULA) s'applique à ton utilisation de Stick : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
  7. Contact : \(AppLinks.contactEmail)
  """
}
