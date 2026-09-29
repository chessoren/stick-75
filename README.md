# Stick

**A 75-day program against doom-scrolling, where the coach who calls you is your own voice.**

You can ignore a coach. Nobody ignores their own voice. Stick clones your voice from a 60-second recording, then *calls you* with it: every morning to set your goals, every evening to check what you actually did, and the moment you open TikTok. Over 75 days, split into five acts, the voice changes from a drill sergeant into a mentor, until you no longer need it.

Built for the [RevenueCat Shipaton 2026](https://revenuecat-shipaton-2026.devpost.com) · Next Gen Award.

- **Demo video:** _add the YouTube link here_
- **Platform:** iPhone, iOS 26+ (SwiftUI, Liquid Glass)
- **Monetization:** RevenueCat: one-time 75-Day Pass plus a weekly subscription

---

## How it works

1. **Onboarding (about 5 minutes).** A short quiz (which apps, how many hours a day, when you crack), a recorded voice sample, and a first "aha" call in your own voice. Then you sign a contract with yourself and take your ticket for the 75 days.
2. **Calls.** AlarmKit rings like a real phone call on the Lock Screen and in the Dynamic Island. When you answer, Stick talks with your cloned voice and listens with speech recognition:
   - **Wake-up call:** sets up to three goals for the day, plus an if-then plan.
   - **Evening debrief:** goes through each goal, yes or no.
   - **Intercept:** a Shortcuts automation rings you the moment a blocked app opens.
3. **Five acts of 15 days.** Each act changes the coach's tone, the number of calls per day and what unlocks:

   | Act | Days | Name | What changes |
   |---|---|---|---|
   | I | 1–15 | The Silence | Drill sergeant, three calls a day |
   | II | 16–30 | The Comeback | Life counter, a replacement habit every morning |
   | III | 31–45 | The Identity | Voice badges, "who are you when nobody's watching?" |
   | IV | 46–60 | The Trial | 15 minutes a day on your honor, weekly trials |
   | V | 61–75 | The Flight | One call a day, plan for life after day 75 |

   A voice "act reveal" plays when a new act starts.
4. **Lapses are not failures.** You get three jokers. Two missed days in a row restart the current act, never the whole program.
5. **Day 75.** The Vault opens and plays the message you recorded to yourself on day one.

Widgets (interactive "Today's goals", "Days held", "Next call"), a Control Center control, Live Activities and a Siri shortcut keep the program on the Home and Lock Screens.

## RevenueCat integration

All purchase code lives in [`App/Services/PurchaseService.swift`](App/Services/PurchaseService.swift).

| What | How |
|---|---|
| **Products** | `stick_pass_75`: non-consumable, the whole program. `stick_weekly`: auto-renewing weekly subscription, a lower-commitment entry. |
| **Access** | A single `member` entitlement attached to both products. The product that unlocked it only decides which plan Me › Subscription shows. |
| **Paywall placements** | Every paywall asks for the offering of its placement: `onboarding` (the "ticket" after the first call), `locked_out` (full-screen lock when access ends) and `settings`. Products, prices and experiments can change per moment from the dashboard, with no app update. It falls back to the current offering. |
| **Live entitlement** | `customerInfoStream` feeds the app. Renewals, expiries, refunds, Ask to Buy approvals and restores on another device lock or unlock Stick without a relaunch. Losing access cancels the scheduled calls; getting it back reschedules them. |
| **Identity** | Sign in with Apple, on device only. The stable Apple user ID becomes the RevenueCat app user ID (`logIn` / `logOut`), so purchases follow the user across devices without a backend. |
| **Subscriber attributes** | `program_day`, `program_act`, `voice_mode` (clone or system). This allows targeting and Charts cohorts such as "day-3 users vs day-60 users". It never sends names, goals or quiz answers. |
| **Customer Center** | RevenueCatUI Customer Center in Me › Subscription: plan details, cancellation with a feedback survey, refund requests. |
| **Honest paywall** | No free trial, on purpose: "a trial is a way out". Prices come only from the store (the buy button stays disabled until the offering loads), the per-day price is shown in the product's currency, and the auto-renewal disclosure, Restore, Terms and Privacy links are always visible. |
| **Errors** | Cancellation is silent. Ask to Buy shows "waiting for approval", offline shows a clear message, and buy and restore can't run at the same time. |

Why a one-time pass? The product *is* the 75 days, so a single ticket matches the promise (commit once, finish) better than an open-ended subscription. The weekly plan stays behind a small "I'd rather try one week first" link for people who aren't ready to commit.

## Running it

Requirements: macOS with **Xcode 26 or later** (iOS 26 SDK) and [XcodeGen](https://github.com/yonaskolb/XcodeGen). The project is defined in `Project.json`, an XcodeGen spec.

```sh
git clone https://github.com/chessoren/stick-75.git
cd stick-75
./scripts/setup.sh          # installs XcodeGen with Homebrew if needed and generates Stick.xcodeproj
open Stick.xcodeproj        # run the "Stick" scheme on an iPhone simulator
```

**No keys or configuration needed:** everything works right after cloning.

- **Purchases.** A Debug build uses the RevenueCat **Test Store**. The paywall shows real offering prices, and "Test valid purchase" unlocks the app in the simulator, with no Apple Developer account. Release builds (TestFlight, App Store) use the App Store app.
- **Voice cloning and AI replies** go through Stick's relay (see below). No private key ships in the app or the repo.

### Server relay

[`supabase/functions/relay`](supabase/functions/relay/index.ts) is a Supabase Edge Function. It holds the Fish Audio and OpenRouter keys, and the app reaches it with the project's public anon key ([`App/Services/Relay.swift`](App/Services/Relay.swift)). It only forwards:

- voice clone creation and deletion;
- text-to-speech;
- chat completions on free models.

It caps request sizes and stores nothing. To host your own, deploy the function, set `FISH_AUDIO_KEY` and `OPENROUTER_KEY` as Edge Function secrets, and point `Relay.baseURL` at your project.

### RevenueCat configuration

These are already set up in the Stick project.

| Item | Value |
|---|---|
| Apps | Test Store (Debug) and App Store (Release) |
| Products | `stick_pass_75`: non-consumable, $79.99 / €79.99 · `stick_weekly`: weekly subscription, $9.99 / €9.99 |
| Entitlement | `member`, attached to all products |
| Current offering | `stick_75`, with packages `$rc_lifetime` → `stick_pass_75` and `$rc_weekly` → `stick_weekly` |
| Placements (optional) | `onboarding`, `locked_out`, `settings`. Without them, the current offering is used. |

The public SDK keys are in `PurchaseService.swift`: `test_…` in Debug, `appl_…` in Release.

### Device-only features

- AlarmKit alarms on the Lock Screen
- Core Haptics ringing
- The Shortcuts app-open automation used for interception
- Sign in with Apple, which needs a signing team

Everything else works in the simulator, including the full onboarding, calls, paywall, purchases and widgets. To run on a real iPhone, set your team and a bundle identifier of your own in `Project.json`, use the same App Group in `Shared/AppGroup.swift`, then regenerate with `xcodegen`.

## Architecture

```
App/
  App.swift             entry point; configures RevenueCat at launch
  Models/               StickStore (@Observable program state, persisted as JSON in the App Group), Act, UserProfile…
  Services/             PurchaseService, CallEngine (call script + speech loop), CallScheduler (AlarmKit),
                        FishAudioService, OpenRouterService, SpeechListener, AuthService (Sign in with Apple)…
  Features/             SwiftUI screens: Onboarding, Paywall, Home, Calls, Call, Me
  Design/               design system: colors, Inter typography, glass cards, haptics
Shared/                 code and strings shared with the widget extension (App Intents, snapshot, Live Activity attributes)
Widget Extension/       widgets, Live Activities, Control Center control
legal/, docs/site/      privacy policy and terms (EN/FR)
```

- **Stack:** SwiftUI with the Observation framework, AlarmKit, ActivityKit, WidgetKit, App Intents, the Speech framework and AVFoundation. RevenueCat and RevenueCatUI are added via Swift Package Manager.
- **Fails gracefully:** every network dependency has a fallback.
  - No voice clone: the system voice is used.
  - No LLM, or the model is too slow: the call follows its script and answers are parsed with keywords.
  - Store unreachable: the last known access is kept.
- **Privacy:**
  - The program lives on the phone.
  - Voice cloning and AI replies each need their own explicit consent.
  - Account deletion wipes local data and deletes the voice clone at the provider.
  - Stick has no account database. Its only server is the relay, which holds the Fish Audio and OpenRouter keys and stores nothing.
- **Localization:** English and French via String Catalogs.

## License

The code is released under the [MIT License](LICENSE). The Inter typeface in `App/Resources/Fonts` is © The Inter Project Authors, under the [SIL Open Font License 1.1](App/Resources/Fonts/OFL.txt).
