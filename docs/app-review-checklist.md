# Stick · Checklist App Review

Le code est prêt pour la review. Cette liste couvre ce qui se fait hors du code : App Store Connect, RevenueCat, le site et les clés.

## 1. Valeurs à remplir dans le code
| Fichier | Clé | Valeur |
|---|---|---|
| `App/Resources/Secrets.local.plist` | `REVENUECAT_KEY` | Clé SDK publique Apple de RevenueCat (`appl_…`) |
| `App/Services/AppLinks.swift` | `contactEmail` | E-mail de contact (affiché dans la politique de confidentialité, les conditions et le site) |
| `App/Services/AppLinks.swift` | `website` | URL du site une fois déployé (voir §5) |
| `App/Services/AppLinks.swift` | `appStoreID` | Apple ID numérique de l'app (App Store Connect › Informations sur l'app), pour le lien d'invitation |
| `docs/site/*.html` | `CONTACT_EMAIL` | Même e-mail que `contactEmail` (rechercher/remplacer) |

Sans `REVENUECAT_KEY`, un build Release affiche « boutique indisponible » : rejet garanti.

## 2. Apple Developer (Certificates, Identifiers & Profiles)
- [ ] Dans Bitrig, reliez l'app à votre fiche App Store Connect pour figer le bundle ID. L'App Group en dépend : `group.<bundle id>` doit rester identique dans `Project.json` et `Shared/AppGroup.swift`.
- [ ] App ID : activer **Sign in with Apple**, **App Groups** et **Time Sensitive Notifications**.
- [ ] Plus tard : demander l'entitlement **Family Controls (distribution)**. Une fois accordé : l'ajouter dans `Project.json` et passer `ScreenTimeService.isAvailable` à `true`. D'ici là, l'interception passe par l'automatisation Raccourcis et rien dans l'app ne mentionne Temps d'écran.

## 3. App Store Connect › Business
- [ ] **Contrat « Paid Apps » signé**, coordonnées bancaires et fiscales validées. Sans ça, les achats intégrés ne fonctionnent pas, même en sandbox, et le reviewer ne peut pas acheter.

## 4. Achats intégrés + RevenueCat
### App Store Connect › Monétisation
| Product ID | Type | Prix (FR) | Nom |
|---|---|---|---|
| `stick_pass_75` | Non-consommable | 79,99 € | Pass 75 jours / 75-Day Pass |
| `stick_weekly` | Abonnement auto-renouvelable, 1 semaine, groupe « Stick » | 9,99 € | Hebdo / Weekly |

- Stick Life (`stick_life_annual`) est retiré de la v1. S'il existe déjà dans App Store Connect, ne le joignez pas à cette version.
- Pour chaque produit : nom et description en EN + FR, une capture d'écran pour la review (le paywall suffit), statut « Prêt à soumettre ».
- Les produits sont revus **avec** le premier build : dans la page de la version, section « Achats intégrés et abonnements », cochez les deux.

### RevenueCat (pour connecter RevenueCat)
1. Créez un projet sur app.revenuecat.com, puis une app **App Store** avec le bundle ID exact de Stick.
2. **Clé In-App Purchase** : App Store Connect › Utilisateurs et accès › Intégrations › In-App Purchase › générer une clé (.p8). Importez-la dans RevenueCat (App settings › In-app purchase key configuration) avec son Key ID et l'Issuer ID. C'est la méthode recommandée pour StoreKit 2.
3. (Optionnel, recommandé) App Store Connect › App › Informations sur l'app › **URL de notification serveur App Store** : collez l'URL fournie par RevenueCat, en production et en sandbox.
4. RevenueCat › **Products** : importez `stick_pass_75` et `stick_weekly`.
5. RevenueCat › **Entitlements** : `pass75` (rattaché à `stick_pass_75`) et `weekly` (rattaché à `stick_weekly`). Le code lit aussi directement les identifiants produit, donc un oubli ici ne bloque pas un client qui a payé.
6. RevenueCat › **Offerings** : une offering `default`, marquée **Current**, avec deux packages : Lifetime → `stick_pass_75`, Weekly → `stick_weekly`.
7. RevenueCat › API keys : copiez la **clé SDK publique Apple** (`appl_…`) dans `REVENUECAT_KEY`.
8. Test : créez un compte Sandbox (App Store Connect › Utilisateurs et accès › Sandbox), lancez sur un vrai iPhone depuis Bitrig, achetez le Pass puis testez « Restaurer ».

## 5. Site : URL de confidentialité et de support (obligatoires)
`docs/site/` contient un site statique : support (`index.html`, `fr.html`), confidentialité (`privacy.html`, `confidentialite.html`), conditions (`terms.html`, `conditions.html`).
- [ ] Remplacez `CONTACT_EMAIL` partout.
- [ ] Déployez le dossier gratuitement (GitHub Pages, Netlify ou Vercel).
- [ ] Dans App Store Connect : **URL de politique de confidentialité** → `…/privacy.html`, **URL d'assistance** → `…/index.html`.
- [ ] Mettez la même URL dans `AppLinks.website`.

## 6. Confidentialité de l'app (étiquette App Store Connect)
Données collectées, **non utilisées pour le suivi** :
| Type | Lié à l'identité | Usage |
|---|---|---|
| Coordonnées › Nom (prénom envoyé au modèle IA si réponses intelligentes activées) | Non | Fonctionnalité de l'app |
| Contenu utilisateur › Données audio (échantillon vocal → Fish Audio) | Non | Fonctionnalité de l'app |
| Contenu utilisateur › Autre contenu (texte des appels, objectifs → OpenRouter / Fish Audio) | Non | Fonctionnalité de l'app |
| Identifiants › Identifiant utilisateur (identifiant Apple anonyme → RevenueCat) | Oui | Fonctionnalité de l'app |
| Achats › Historique d'achats (RevenueCat) | Oui | Fonctionnalité de l'app |

Aucune adresse e-mail n'est collectée : Sign in with Apple ne demande ni nom ni e-mail.

## 7. Classification par âge
Répondez au questionnaire honnêtement. Points à cocher : contenu généré par IA / chatbot (réponses du modèle pendant les appels), ton de coach ferme. La politique de confidentialité indique **16 ans et plus** : visez 16+.

## 8. Métadonnées (brouillon)
**Nom** : Stick — 75 days, your voice
**Sous-titre (EN)** : Your own voice calls you off TikTok
**Sous-titre (FR)** : Ta propre voix t'appelle pour lâcher TikTok
**Catégorie** : Santé et forme (secondaire : Productivité)
**Mots-clés (EN)** : screen time,tiktok,focus,habit,75 days,digital detox,coach,voice,discipline,goals
**Mots-clés (FR)** : temps d'écran,tiktok,concentration,habitude,75 jours,détox numérique,coach,voix,discipline,objectifs

**Description (EN)**
You can ignore a coach. You can't ignore yourself.
Stick clones your voice (only yours, with your consent) and calls you: every morning to set 1–3 real goals, the second you open TikTok, and every night for the debrief. 75 days, five acts, three jokers, no reset to day one.
• Wake-up call in your voice, goals pushed to your widgets
• Interception when TikTok opens, through a one-minute Shortcuts automation
• Evening debrief that checks every goal
• Hours recovered, converted into books, runs, nights of sleep
• Voice badges, weekly trials, and the Vault: a message from day 1, played on day 75
Stick is a digital-wellbeing coach, not a medical product. Microphone and speech recognition are required for calls.
75-Day Pass: one-time purchase. Weekly: auto-renewing subscription, cancel anytime in Settings.
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: <votre URL>/privacy.html

**Description (FR)**
Tu peux ignorer un coach. Pas toi-même.
Stick clone ta voix (seulement la tienne, avec ton consentement) et t'appelle : chaque matin pour fixer 1 à 3 vrais objectifs, à la seconde où tu ouvres TikTok, et chaque soir pour le bilan. 75 jours, cinq actes, trois jokers, jamais de retour au jour 1.
• Appel du réveil avec ta voix, objectifs poussés dans tes widgets
• Interception quand TikTok s'ouvre, grâce à une automatisation Raccourcis d'une minute
• Bilan du soir qui vérifie chaque objectif
• Heures récupérées converties en livres, runs, nuits de sommeil
• Badges vocaux, épreuves hebdo, et le Coffre : un message du jour 1, rejoué au jour 75
Stick est un coach de bien-être numérique, pas un produit médical. Micro et reconnaissance vocale nécessaires pour les appels.
Pass 75 jours : achat unique. Hebdo : abonnement renouvelé automatiquement, résiliable à tout moment dans Réglages.
Conditions d'utilisation (EULA) : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Politique de confidentialité : <votre URL>/confidentialite.html

## 9. Notes pour App Review (à coller dans « Notes »)
```
Stick is a digital-wellbeing coach that calls the user in their OWN cloned voice.

Consent and AI (5.1.2(i)): before any recording, the user sees who receives what and gives explicit, unchecked-by-default consent: (1) the voice sample goes to Fish Audio to build a private synthetic voice of the user's own voice; (2) optionally, the text of calls goes to OpenRouter (LLM) to generate replies. Without (2), calls run on a fixed script. Both can be changed in Me › My voice. Users can also skip cloning entirely and use a system voice.

No backend, no user-generated content shared with other users. Sign in with Apple is optional, requests no scopes (no name, no email) and is only used as the RevenueCat app user id so purchases follow the user. The authorization code is never exchanged with Apple's servers, so no refresh token exists to revoke. Account deletion: Me › Account › Delete everything (deletes the voice clone at Fish Audio via its API, all local data, and forgets the Apple sign-in).

Purchases: 75-Day Pass (non-consumable) and Weekly (auto-renewable). Price, duration, Terms (Apple EULA) and Privacy Policy are on the paywall; Restore is on the paywall and in Me › Subscription.

AlarmKit schedules the user's wake-up and debrief calls at times they choose. No CallKit, no VoIP push. The "audio" background mode keeps an active voice conversation running if the screen locks mid-call.
Interception uses a user-created Shortcuts automation that opens stick://intercept; the app explains each step.

How to test: complete onboarding (a 25-second recording is enough), tap "Ring me" for the first call, buy the 75-Day Pass with the sandbox account, then on Today tap the lightning button to start a call and answer out loud.
```
Joignez une vidéo d'environ 1 minute : consentement → enregistrement → premier appel → paywall → Aujourd'hui → un appel complet.

## 10. Avant d'appuyer sur « Soumettre »
- [ ] Build Release avec `REVENUECAT_KEY` rempli, et un achat sandbox réussi sur un vrai iPhone.
- [ ] URL de confidentialité et de support en ligne ; `AppLinks` rempli.
- [ ] Captures d'écran iPhone 6,9" (et 6,5" si demandé) : accroche, appel entrant, Aujourd'hui, paywall, widget. Rien qui montre la ligue ou un parrainage.
- [ ] Conformité export : déjà déclarée dans Info.plist (pas de chiffrement non exempté).
- [ ] Test sur appareil : les alarmes sonnent sur l'écran verrouillé, l'automatisation Raccourcis ouvre un appel, un appel du matin complet enregistre des objectifs, la suppression du compte ramène à l'onboarding.
