# Stick · App Review checklist

Everything the app does is in the code. Everything below is what you do in App Store Connect and on the web before submitting.

## 1. Accounts and keys
- [ ] Apple Developer Program active. In Bitrig, connect the app record so the bundle ID becomes permanent (the App Group id is derived from it).
- [ ] Request the **Family Controls (distribution)** entitlement for the app bundle ID. Form: https://developer.apple.com/contact/request/family-controls-distribution . Use case: "digital wellbeing, user chooses apps to shield, no parental features". Until approved, the Shortcuts automation covers interception.
- [ ] Request **Time Sensitive Notifications** capability in the app ID (backup ringer).
- [ ] RevenueCat project → Apple App Store app → paste the public SDK key into `App/Resources/Secrets.local.plist` (`REVENUECAT_KEY`).
- [ ] Supabase project → run `supabase/schema.sql`, enable **Anonymous sign-ins**, paste URL + anon key.
- [ ] Move Fish Audio and OpenRouter calls behind a Supabase Edge Function before scale (keys shipped in the binary can be extracted). Not a review blocker.

## 2. In-app purchases (App Store Connect › Monetization)
| Product ID | Type | Price (FR) | Name |
|---|---|---|---|
| `stick_pass_75` | Non-consumable | €79.99 | 75-Day Pass |
| `stick_weekly` | Auto-renewable, 1 week, group "Stick" | €9.99 | Weekly |
| `stick_life_annual` | Auto-renewable, 1 year, group "Stick" | €129.99 | Stick Life |
- Localize each product in EN + FR. Add a review screenshot for each (any screenshot of the paywall).
- In RevenueCat: entitlements `pass75`, `weekly`, `life`; one offering "default" with the three packages.
- Products are reviewed **with** the first build. Submit them together.
- Sandbox: create a Sandbox Apple Account, test on a real device via Run on…

## 3. App Privacy (nutrition label)
Collected, **not** linked to identity, **not** used for tracking:
- Contact Info › Name (first name)
- User Content › Audio Data (voice sample, call audio), Other User Content (goals, transcripts, identity sentence)
- Identifiers › User ID (anonymous Supabase id)
- Purchases › Purchase History
Third parties to name in the privacy policy URL: Fish Audio, OpenRouter, Supabase, RevenueCat, Apple Speech.
Privacy policy URL: host `legal/privacy-en.md` (and `-fr`) on your site. The same text is inside the app (Me › Privacy policy, and on the paywall).
Terms: the paywall links to Apple's standard EULA plus in-app terms (`legal/terms-*.md`).

## 4. Metadata (draft)
**Name**: Stick — 75 days, your voice  
**Subtitle (EN)**: Your own voice calls you off TikTok  
**Subtitle (FR)**: Ta propre voix t'appelle pour lâcher TikTok  
**Category**: Health & Fitness (secondary: Productivity)  
**Age rating**: 12+ (infrequent mild mature themes: firm coaching language). No medical claims anywhere.  
**Keywords (EN)**: screen time,tiktok,focus,habit,75 days,digital detox,coach,voice,discipline,goals  
**Keywords (FR)**: temps d'écran,tiktok,concentration,habitude,75 jours,détox numérique,coach,voix,discipline,objectifs  

**Description (EN)**  
You can ignore a coach. You can't ignore yourself.  
Stick clones your voice (only yours, with your consent) and calls you: every morning to set 1–3 real goals, the second you open TikTok, and every night for the debrief. 75 days, five acts, three jokers, no reset to day one.  
• Wake-up call in your voice, goals pushed to your widgets  
• Interception when a blocked app opens (Screen Time or a Shortcuts automation)  
• Evening debrief that checks every goal  
• Hours recovered, converted into books, runs, nights of sleep  
• Weekly league, badges, and the Vault: a message from day 1, played on day 75  
Stick is a digital-wellbeing coach, not a medical product. Requires microphone and speech recognition for calls.

**Description (FR)**  
Tu peux ignorer un coach. Pas toi-même.  
Stick clone ta voix (seulement la tienne, avec ton consentement) et t'appelle : chaque matin pour fixer 1 à 3 vrais objectifs, à la seconde où tu ouvres TikTok, et chaque soir pour le bilan. 75 jours, cinq actes, trois jokers, jamais de retour au jour 1.  
• Appel du réveil avec ta voix, objectifs poussés dans tes widgets  
• Interception quand une app bloquée s'ouvre (Temps d'écran ou automatisation Raccourcis)  
• Bilan du soir qui vérifie chaque objectif  
• Heures récupérées converties en livres, runs, nuits de sommeil  
• Ligue hebdo, badges, et le Coffre : un message du jour 1, rejoué au jour 75  
Stick est un coach de bien-être numérique, pas un produit médical. Micro et reconnaissance vocale nécessaires pour les appels.

## 5. App Review notes (paste in "Notes")
```
Stick is a digital-wellbeing coach. It clones the USER'S OWN voice only, after an explicit consent screen (Guideline 5.1.2(i)): the sample is sent to Fish Audio to build a private synthetic voice; conversation text goes to OpenRouter. Both are named in-app before any recording.
No login. An anonymous Supabase account stores the league score; users delete it (and all data) from Me › Delete my account and data (5.1.1(v)).
Purchases: 75-Day Pass (non-consumable) and two auto-renewable plans, with price, duration, Terms and Privacy on the paywall. Restore Purchases is on the paywall.
Screen Time (Family Controls) is used only to shield apps the user picks; if the entitlement is not present the app degrades to a Shortcuts automation.
AlarmKit schedules the user's wake-up and debrief calls at times they choose. No CallKit, no VoIP push. Background audio keeps a call going if the screen locks.
To test quickly: complete onboarding (a 25-second recording is enough), tap "Ring me", then on Today tap the lightning button to trigger a call. Demo video: <link>.
```
Attach a 1-minute screen recording of: consent → recording → aha call → paywall → Today → a call.

## 6. Before you tap Submit
- [ ] Build with `REVENUECAT_KEY` set: without it, Release builds show "store unavailable" (mock purchases only exist in Debug).
- [ ] Privacy policy URL live. Support URL live (a page with support@stick.app).
- [ ] Referral links `https://stick.app/r/<code>` should at least redirect to the App Store page.
- [ ] Screenshots: 6.9" and 6.5" iPhone (onboarding hook, incoming call, Today, League, paywall, widget).
- [ ] Export compliance already answered in Info.plist (no non-exempt encryption).
- [ ] Test on a device: alarms ring on the Lock Screen, the Shortcuts automation fires, a full morning call saves goals.
