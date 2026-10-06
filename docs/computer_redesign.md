# Computer redesign: more comic, more fun

Brainstorm + design for the computer minigames (jam themes: **comic**, **light**, **twist**). Visit 1 is fixed by the user (see `plan.md` → "Computer: first visit"). Everything else here is a proposal for the team to argue about. The framework and the first three minigames were written by teammate PiBot314 (`minigames/computer/`), and this redesign builds on them. Anything that changes their code is marked **[consult teammate]**, because they may still be working on their branch.

---

## 1. Diagnosis (what we have now)

The teammate's framework is solid: the host, registry, per-minigame config resources, `Computer.open()/queue()` and the step semantics in `EventManager` all fit the story well. The ideas are good too. The problem is the **presentation and the feedback**: the jokes are written down but never *performed*.

### The vim screen (`computer.tscn`)
- **Not comic:** a dark slate background (`#1C1F26`), a green `-- INSERT --` status bar and monospace text read as "hacker terminal", which is the opposite of a Comic Sans office drone. Nothing on it is drawn, outlined, bouncy or loud.
- **Not fun:** typing has no goal and no response. You can type forever and nothing reacts: no narrator, no word-count milestone, no consequence. The `Score` number has no meaning to the player (score of *what*?).
- **The Power button is a plain exit.** In a Stanley-Parable game an exit button is a comedy opportunity, and right now it's only a door.
- **Good bones:** `buffer` as the shared document, minigames that write into it (corporate_speak appends its sentence) and the "Esc is deliberately not an exit" choice are all things to keep. The vim idea also matches the plan's "restart power to exit vim" note, so it should come back later as a **gag** (§5, "Exit vim") instead of being the wallpaper.

### `ad_popup`
- **Strong core:** a tiny real X, decoys that spawn more ads, and an X that dodges once you get good at it. That's exactly the subverted-affordance humour we want.
- **Not comic enough:** each ad is a plain panel with one headline and one button. Real joke ads work through *visual* excess: clashing colours, flashing borders, fake download buttons, a "Hot singles" stock photo. The headlines are generic internet jokes with no tie to our world (light bulbs, comics, the office, the narrator).
- **Escalation is capped too early:** `max_concurrent = 4` and `max_dodges = 2`, so the storm never gets big enough to be funny, and the dodge happens so quickly that the player may not even notice it was a joke.
- **No punchline:** the last ad closes and... the next step starts. The comic rule says the third beat must be the biggest and different.
- **Precision pain:** an 8 px X on a scaled screen is "annoying", not "funny". The funny version is an X that's *findable but behaves badly* (runs, hides behind another ad, asks "are you sure?").

### `corporate_speak`
- **Nice premise and writing.** The `{word:points|...}` sentence format is a great authoring tool; keep it.
- **No decision tension:** the right answer is always the longest buzzword, so after one sentence it becomes a pattern-matching chore. The `eepy` / `really hate working here` sentence is the funniest one *because* it breaks that pattern.
- **Feedback is numbers:** "+10", "Corporate alignment: +43". Nobody reacts: no boss, no narrator, no consequence.
- **It's a form, not a scene.** There's no recipient, no character and no stakes.

### `bot_check`
- **Good jokes in the fail messages** ("Your click was too precise", "We detected unusual human activity").
- **Pass/fail is pure luck:** you pass after a random 2–6 clicks, so the player learns nothing and has nothing to get better at.
- **"Click me if you are a bot"** fails the step and restarts it unchanged. The joke lands once, then it's a loop with no new information.
- **The close X after 3 s also passes**, so the optimal play is to wait, which undercuts the whole minigame.
- **It's a single beat.** [Neal.fun's *I'm not a robot*](https://neal.fun/not-a-robot/) shows how far this joke stretches when every level is a new absurd variant.

---

## 2. Principles from comedic / meta desktop games

| Game | What makes it funny | What makes it fun | Steal |
|---|---|---|---|
| [The Password Game](https://neal.fun/password-game/) (Neal Agarwal) | Rules escalate from reasonable to absurd (sponsors, Paul the chicken, the password catching fire) | Every rule is readable, checkable live, and stacks on the previous ones | Live rule list with green/red ticks; rule-of-three then derail |
| [I'm Not a Robot](https://neal.fun/not-a-robot/) (Neal Agarwal) | 48 CAPTCHA levels that start normal and go surreal (Rorschach, park the car, "select the AI men") | Each level is 10–30 s with a new verb | One familiar UI, many short absurd variants |
| [There Is No Game: Wrong Dimension](https://store.steampowered.com/app/1240210/) | A grumpy narrator-game argues with you; UI elements are physical objects you break | Puzzles are the UI itself (drag the title letters, pull the menu apart) | The UI is the toy; the narrator reacts to *what you touched* |
| [Frog Fractions](https://twinbeard.com/frog-fractions) | A fake edu-game whose genre keeps twisting | Constant surprise; nothing overstays | Genre twist per visit |
| [Hypnospace Outlaw](https://store.steampowered.com/app/844590/) | A lovingly bad fake OS/internet: tacky pages, popups, a sentient assistant, ads | Exploring a dense, consistent fake world | Fake OS with a strong era aesthetic and an annoying mascot |
| [Please, Don't Touch Anything](https://store.steampowered.com/app/354240/) | One button you're told not to press | Every interaction is an experiment with a visible result | Forbidden buttons; react to every click |
| [The Stanley Parable: Ultra Deluxe](https://store.steampowered.com/app/1703340/) | The narrator comments on the player's exact actions, including idling and refusing | Agency: disobedience is content | Narrator lines for *refusing*, *idling*, and *repeating* |
| [Emily is Away](https://store.steampowered.com/app/417860/) | Chat UI nostalgia; you type, but the message is pre-written | Keyboard mashing produces perfect sentences | "Any key types the right text" trick for scripted typing |
| [Windosill](https://vectorpark.com/) (Vectorpark) | Tactile, springy, surprising objects | Every object responds with physical juice | Squash-and-stretch on every click |
| [Absurdle](https://qntm.org/files/absurdle/absurdle.html) / Wordle parodies | A familiar daily-game UI that is secretly adversarial | Still solvable, so you're outsmarting it | The UI cheats against you, but there's a real way to win |
| [Universal Paperclips](https://www.decisionproblem.com/paperclips/) | A deadpan UI that slowly reveals something huge | Numbers that move; new buttons appear | Status-bar numbers that matter and escalate |
| [Hidden Folks](https://store.steampowered.com/app/435400/) | Mouth-made sound effects for everything | Every click answers with a silly sound | Record our own "pew"/"boop" mouth SFX; the team voices the narrator anyway |
| [Windows 93](https://www.windows93.net/) | A parody OS stuffed with joke apps | Every icon is a surprise | Desktop icons as joke hooks |

**Distilled rules for our computer:**
1. **Perform the joke visually.** Comic panels, thick outlines, onomatopoeia ("POW!" when an ad dies), and squash-and-stretch. If you can screenshot it and it isn't funny, it isn't comic enough.
2. **Rule of three, then derail.** Beat 1 sets up the rule, beat 2 confirms it, beat 3 breaks it in a bigger, different way.
3. **Subvert one affordance per minigame.** Close buttons that run, checkboxes that judge you, a progress bar that goes backwards. Pick one per game; don't stack five.
4. **The narrator reacts to the player's *specific* action** (which font, how many ads, staying silent at the mic), plus idle and refusal lines. Cheap to write, huge payoff.
5. **Quick feedback:** every click gets sound + motion + a visible result within 100 ms.
6. **Short sessions:** 20–60 s per beat, 3–5 minutes per visit. Leave before the joke wears out.
7. **Readable goal, absurd obstacle.** The player always knows what "done" is (a goal line in the window title or a checklist). The comedy comes from the obstacle, never from confusion.
8. **Always winnable.** Every frustration gag has a guaranteed exit after N tries (the mic fails exactly 5 times and the X dodges at most N times). Luck never decides.
9. **Themes leak in:** light (brightness, night mode, eco mode, the monitor glow), twist (rotating windows, twisting letters, the twist-input keys) and comic (fonts, panels, captions).

---

## 3. "Comic OS": a fake desktop replaces the terminal

Working name: **ComicOS 95** (boot jingle optional). The screen becomes a desktop. Whatever app is running is a **window** on it, so the background is always "what's running live", never a terminal.

### On screen
- **Wallpaper:** a halftone (Ben-Day dots) sky-blue comic panel with a hand-drawn office horizon, or the company logo. Lots of jokes can live here (see below).
- **Desktop icons** (all clickable, most do nothing useful, but every one has a narrator line or a gag, `once`):
  - **My Documents**: one file, `comic_script_FINAL_final2.cmc`. Opens Comic Writer.
  - **Recycle Bin**: full, and contains "your dreams of stand-up comedy.txt" (ties to the protagonist backstory in the plan).
  - **Light Bulb.exe**: does nothing on visit 1. Later it toggles the screen dimmer as a hint, or the narrator says "That's not how electricity works."
  - **DO NOT CLICK.exe**: Please-Don't-Touch-Anything gag; each click escalates (window → "I said don't" → it closes itself and deletes its icon → the next visit it's back, bigger).
  - **Inky** (the assistant, see §5) sits in the corner from visit 2 on.
- **Taskbar** (bottom, chunky outlines):
  - A **"Start"** button labelled **"Stop"**. Its menu: *Shut Down* (greyed out: "You don't have permission to leave"), *Sleep* (the bank-balance gag, §5), *Log Off* ("Logging off is a privilege of salaried employees"), *Run...* (opens a run box that only accepts "Comic").
  - **Open-app buttons** for every window.
  - **Tray:** wifi icon with one bar; a **brightness** icon (light theme hook); **battery 3%** on a *desktop* PC ("plugged in, not charging"); and a speech-bubble notification icon.
  - **Clock:** shows the office time (the wall clocks say ~6:59). It ticks normally, then on later visits it **runs backwards** like C2's clock, or reads `OVERTIME:OVERTIME`.
- **Notifications** (toasts, comic speech balloons, bottom-right): the narrator's second channel. Examples: "HR: Reminder that overtime is a state of mind." "Facilities: Lights will be turned off at 7:00 to save energy." (foreshadowing visit 1's blackout) "Your font license has expired." "IT: Your password expires in 0 days."
- **Cursor:** a white cartoon glove (Mickey-style). It goes into a "pointing" pose over buttons and a "shrugging" pose while waiting. Cheap: two textures with `Input.set_custom_mouse_cursor`.

### Windows (one reusable `AppWindow`)
- Thick black outline, an off-white "paper" body, a coloured title bar in Comic Relief Bold, and three buttons: minimise (`_`), maximise (`□`), close (`X`). The close button is real *unless* a minigame says otherwise, so it's the place to hide jokes.
- **Pop in/out** with squash-and-stretch (the teammate's `_pop_in` back-ease tween already does this; generalise it). Closing a window plays a burst word ("POOF!", "BYE!") in a jagged comic balloon.
- Draggable by the title bar. Some minigames ask the player to drag.
- Each minigame *is* an app in its window: Comic Writer (the editor), Mic Login, Font Picker, ads, MemoMail (corporate speak), CAPTCHA, Updater and so on.

### Narrator hooks
- Inside the computer, narrator subtitles could render as **yellow comic caption boxes** (top-left, square-cornered, Comic Neue Italic) instead of bottom subtitles, which is how comics show a narrator. **[consult team]**: this is the global `Narrator` UI; it could be a per-scene style switch.
- Hooks every app gets for free from `AppWindow`/`Minigame`: on open, on idle (no input for N s), on repeated failure (Nth fail), on refusal (trying to close something you shouldn't), on finish.
- The desktop itself has idle lines: "You're staring at the wallpaper. It was the cheapest one."

### How light and twist leak in
- **Light:** a brightness tray icon; the screen **flickers** a few seconds before each blackout (a full-screen dim tween + a buzz); every blackout at the computer ends with a **CRT-off** effect (the picture squashes to a white line, then a dot, then black) before the fade to the dark office. "Night Light", "Eco Mode" and "Dark Mode" are jokes in the apps. The monitor is the last light in the room.
- **Twist:** windows that **rotate** a few degrees when something goes wrong and twist back when fixed; on visit 3 the whole desktop tilts more each time the player fails. Letters in the document twist out of place (§5, "Twisted text"). The twist-input keys (B-H-Y-T-F-V around G, `TwistInput` in `core/input/`) can drive an in-computer gag too.
- **Comic:** every font on screen is a Comic font; the fonts *are* the theme.

### Recurring wallpaper gag (cheap, high payoff)
The wallpaper changes slightly each visit: visit 1 a sunny comic panel; visit 2 the same panel with the sun swapped for a light bulb; visit 3 the bulb is broken and a small gnome (the plan's light-messing imp) is in the corner. Nobody points it out, unless the player clicks it.

---

## 4. Visit 1, in detail (user-fixed beats)

Target length: about 3 minutes. Each beat is one queued minigame id, so the existing `EventManager` steps play them in order with no changes:
`Story.FIRST_VISIT = [&"mic_password", &"font_picker", &"ad_storm"]`.

### Beat 1: `mic_password` ("Say your password")
**Setup:** the desktop boots to a login window: "VoiceLogin™ by ComicOS. Your voice is your password." A cartoon microphone with a chrome grille and a big red "● REC" sits next to a waveform panel showing *live* audio from the real mic.

**Flow and escalation (exactly 5 fails, then the text box):**
| Attempt | Trigger | Screen | Narrator / caption |
|---|---|---|---|
| (intro) | window opens | "Please say your password out loud." | "Go on. Nobody's listening. Except the computer. And me." |
| 1 | voice detected, then 0.8 s of silence (or 6 s of nothing → "We couldn't hear you") | "Processing..." spinner 1.2 s → ❌ "Sorry, I didn't catch that." | — |
| 2 | same | "Did you say: **'pastry bird'**?" with a [No] button only | "Pastry bird. Strong password." |
| 3 | same | "Please speak in Comic Sans." The waveform redraws in a wobbly comic style | "You can't speak in a font. I checked." |
| 4 | same | "Audio received. Audio **not processed**. (Budget cuts.)" The mic icon droops | "They bought the microphone. They did not buy the part that listens." |
| 5 | same | "LOUDER." The waveform panel shakes; then ❌ "Too loud. HR has been notified." | "Five times. You said your password out loud five times, in an open-plan office." |
| fallback | automatic | the mic slides off; a plain text box drops in: "Or just type it, I guess." | — |
| type | any non-empty text + Enter | "Password accepted. It was 'password'. Everyone could hear it, by the way." | "It accepts anything. That's the security." |

**Details:**
- **Silent player** (denied permission, no mic, or just refusing): a 6 s timeout per attempt still counts as an attempt ("We couldn't hear you"), so the beat finishes either way. Extra `once` line on the first silent attempt: "The strong, silent type. The computer does not support that type."
- **The waveform must always look alive.** If the real input stays under a noise floor for 1.5 s (permission denied, muted or no device), draw a **fake** waveform (smoothed noise that also reacts to keypresses and mouse movement). The text above it says "Simulated waveform (actual waveform unavailable)", which is itself a joke.
- **Real-time detail that sells it:** the waveform reacts to the player's voice within a frame, so the first instinct is "whoa, it works". That's the setup that makes the five fails funny.
- **Done:** any password typed → `complete()`. Optionally store it in `GameState.password` so visit 3 can say "Your password 'banana' has expired."
- Scope: **M**.

**Feasibility (Godot 4.7):**
- **Project setting** `audio/driver/enable_input = true` (off by default; input won't work without it). [Docs: AudioStreamMicrophone](https://docs.godotengine.org/en/stable/classes/class_audiostreammicrophone.html)
- **Bus:** add a `Mic` bus to `default_bus_layout.tres` with `mute = true` (so you don't hear yourself; Godot's mic-record demo uses the same muted-bus trick) and an `AudioEffectCapture` (or `AudioEffectSpectrumAnalyzer` for bars). An `AudioStreamPlayer` with `stream = AudioStreamMicrophone.new()` and `bus = "Mic"` plays only while the beat runs. Each frame, read `capture.get_buffer(capture.get_frames_available())` and compute RMS/peak per chunk into a ring buffer, then draw it as a `Line2D` or with `_draw()` bars. A simple voice-activity detector: RMS above a threshold for ≥ 0.3 s = "speaking"; then 0.8 s below = "done".
- **macOS:** in the editor the OS asks for mic permission for the Godot app the first time input starts. In an export, set the macOS preset's `privacy/microphone_usage_description` (joke text: "ComicOS needs your microphone so it can not listen to you.") and `codesign/entitlements/audio_input = true` (needed under the hardened runtime). Neither is set in `export_presets.cfg` yet.
- **Permission denied:** CoreAudio delivers silence (all zeros), so nothing crashes; the fake-waveform fallback above covers it. Verify on a real export that the prompt appears when the mic stream starts, not at game launch. If it appears at launch, keep `enable_input` on anyway and joke about it ("ComicOS would like to access your microphone." — "Why?" — "Teambuilding.").
- **Privacy:** nothing is recorded or stored; the buffer is discarded every frame. Say so in the credits or a README.

### Beat 2: `font_picker` (choose a Comic font)
**Setup:** Comic Writer opens on a "Choose a font for your document" dialog: a list with a live preview line ("The quick brown fox jumps over the lazy deadline."). The narrator says nothing yet.

**List (top to bottom):** Times New Roman, Arial, Helvetica, Calibri, Garamond, Papyrus, Impact, Wingdings, Comic Sans MS, Comic Neue, Comic Relief, Comic Shanns Mono. Previews of non-Comic fonts use `SystemFont` (`font_names = ["Times New Roman", "Times"]` etc.); if one isn't installed it falls back to the default, which is fine since it's about to be rejected anyway. We don't ship those fonts.

**Rules and escalation (non-Comic picks):**
| Wrong pick # | What happens |
|---|---|
| 1 | Narrator: "Times New Roman. For a comic. Bold choice. Wrong, but bold." The font's row gets a red strikethrough and stays struck out. |
| 2 | Narrator: "No." The row strikes out, and the *remaining* non-Comic rows start to wobble. |
| 3 | Narrator: "Let me help." The non-Comic rows rename themselves with a twist animation: "Times New *Comic*", "Ari*al Comic*", "Helvetica (Comic Edition)". Choosing one of them still fails: "That's a disguise." |
| 4+ | Random from a pool: "The answer is in the name of the game. Well, not the name of the game. The theme.", "I'm not angry. I'm comic.", "Wingdings is not a comic font. It is barely a font." |
| Papyrus | Special `once`: "Papyrus is for avatar-themed restaurants." |
| Wingdings | The preview renders as symbols; special line. |
| **Comic Sans MS** | Special: "Comic Sans is licensed by Microsoft. Your employer doesn't pay for licences. Or overtime." The row greys out. (This is true for the project too, which is why we ship the look-alikes.) |

**Done:** any of Comic Neue / Comic Relief / Comic Shanns Mono → a confetti burst + "KA-CHING!" balloon; the narrator: "Comic Neue. See? You can follow simple instructions." The document opens in that font. Store it in `GameState.document_font` (the Writer uses it for the rest of the game). Choosing the *mono* one gets a bonus line: "A monospace comic font. For the programmer who also does comics. Or the reverse."
Scope: **S–M**.

### Beat 3: `ad_storm` (start typing → ads)
**Setup:** Comic Writer is open with a blinking cursor, a goal line in the title bar ("comic_script_FINAL_final2 — target: 1 page"), and a page counter at "0%".

**Flow:**
1. **The player types.** Use the Emily-is-Away trick: whatever they press, the document writes the *opening line of the comic script* one character per keypress ("PANEL 1. A man sits at a desk. The lights are on. For now."). It feels good and sets up the blackout. *Ad 1 pops up on the 3rd keypress* (instant cause-and-effect = funny).
2. **Wave 1 (setup), 3 ads, one at a time:** each with a real, findable X. They teach the rule "close the ads". Headlines tied to our world: "LIGHT BULBS 90% OFF — limited time, limited light", "HOT SINGLE FONTS IN YOUR AREA (Comic Sans wants to meet you)", "Download more overtime FREE".
3. **Wave 2 (confirm + escalate), triggered by typing again:** 3 ads at once with varieties:
   - **Runner:** the X dodges 2–3 times (the existing dodge, slower so it reads), then gives up with a "😮‍💨 fine" balloon.
   - **Matryoshka:** closing it opens a smaller copy of itself inside, 3 levels deep.
   - **Fake X:** a big X that is actually the decoy ("CLOSE" → opens 2 ads); the real X is a tiny "no thanks, I hate saving money" text link. Each decoy click shows a comic "BOING!" and spawns at most 2 extra ads, with a hard cap so it never exceeds ~8 windows.
   - **Countdown:** "Skip ad in 5... 4... 7... 12..." (counts *up* after 4), then it skips itself anyway.
4. **Wave 3 (derail), the punchline:** one huge ad slides up covering the document: **"⚡ ECO MODE ⚡ Is your office too BRIGHT? Save up to 100% on electricity! [TURN OFF LIGHTS]"**, with a microscopic X. The X works, *and* the big button works, and both do the same thing: "Thank you for saving energy!" → the screen brightness dips, flickers twice → **CRT-off** → lights out. The twist is that the player (or the ad) turned the lights off.
5. **Narrator during the storm:** wave 1: "Oh no. Advertising. In a workplace. Who could have foreseen this." Decoy click #1: "That was an ad pretending to be a button. Like most of management." The runner: "It's scared of you. Respect." Wave 3: "Don't. Don't press the—" → blackout → `lights_out_1` in the dark office.

**Done:** all ads closed (the last being the Eco Mode ad) → `complete()` → the host plays the blackout (see §7, T7). Typing between waves adds to the script and the progress %; it's never required beyond the triggers (wave 2 starts after 6 more keypresses or 8 s of idling, so nobody gets stuck).
Scope: **M** (a wave controller around the existing `ad_popup`, plus 3 ad variants).

---

## 5. Existing minigames improved + new ones

Format: **hook / controls / 3-beat escalation / narrator lines / scope / visit**.

### Improved: `ad_popup` → ad variants (used by `ad_storm`)
- **Hook:** keep the teammate's tiny X, decoy spawning and dodging. Add a **visual skin**: clashing gradient, flashing border (blink 2 Hz), a starburst "FREE!" sticker, a fake stock-photo blob, and each headline in a different Comic font size.
- **Controls:** mouse.
- **Escalation:** the variants above (Runner, Matryoshka, Fake X, Countdown, Eco Mode finale) instead of only one dodging behaviour. Each variant can be a config preset (`.tres`) on the *same* scene where possible: `close_button_size`, `max_dodges`, `skip_countdown` and the headlines are already config fields.
- **Narrator:** per variant, `once`.
- **Scope:** M · **Visit:** 1 (storm). A small single ad could return in visits 2/3 as a running gag ("Ad blocker expired").
- **[consult teammate]:** the variants need new config fields (`variant`, `nested_depth`, `countdown_lies`) and a bigger `max_concurrent`.

### Improved: `corporate_speak` → **MemoMail: Reply All**
- **Hook:** it's an email from **your boss** (a cartoon avatar with a tie) in a mail app window: "Re: Re: Re: Re: why is the deliverable in Comic Sans??" You must write the reply by filling the blanks (keep the `{word:points|...}` format; the content is great).
- **Controls:** click a blank → pick a word (as now), then press **Send**.
- **Make choices matter:** the boss's **mood meter** (a face going 😐 → 🙂 → 🤩 or → 😡) reacts *live* to each word, not only on submit. The twist: on the 3rd email, pure buzzwords make the boss reply "I have no idea what this means. Promoted." while the honest option ("I really hate working here") gets "Same. Don't tell anyone." Both outcomes complete the step; the funny part is the reaction.
- **Escalation:** email 1 is a normal reply (learn the system). Email 2 is CC'd to 40 people, the mood meter becomes 40 faces, and each word flips some of them. Email 3: **Reply All** gets pressed by itself ("Send to: Entire Company (4,012)"), and the narrator panics with you.
- **Narrator:** "Corporate speak. A language with no native speakers." / On "eepy": "Did you just say eepy to your manager." / Reply All: "Oh. Oh no. Everyone saw that."
- The sentence still appends to the document (the comic script now contains corporate jargon; the narrator can comment on it later).
- **Scope:** M · **Visit:** 2.
- **[consult teammate]:** this keeps their scene logic and sentence format but changes the frame (mail window, boss reactions, multiple emails per run).

### Improved: `bot_check` → **CAPTCHA Gauntlet**
- **Hook:** "Prove you're human to continue." A sequence of **short, absurd but solvable** CAPTCHAs (I'm Not a Robot style), each 10–20 s. Keep the teammate's checkbox, "click me if you are a bot" button and fail messages as level 1.
- **Controls:** mouse (and drag).
- **Levels (pick 3–5 per run):**
  1. **Classic:** the checkbox. It needs exactly 3 clicks (deterministic, not random) with the existing fail messages in order. The "I am a bot" button is honest: clicking it shows "Thank you for your honesty. Bots get the day off." then "Just kidding" and a restart, which is a different joke each press (rule of three, then it hides).
  2. **"Select all squares with a light bulb":** a 3×3 grid; some squares are *on* bulbs, some are off, and one is the sun. Correct = select all squares with a bulb, lit or not. The twist: the second time, "Select all squares where the lights are **on**", and while you're choosing they go out one by one (theme callback). Pressing Verify with none selected passes ("Correct. There are no lights.").
  3. **Twisted text:** distorted CAPTCHA letters that literally *twist* (rotating per letter); type them. Each wrong attempt twists them more, until the answer is "COMIC" written plainly in Comic Neue.
  4. **"Draw a circle to prove you're human":** with the mouse; any shape passes with a grade ("C+: 'circle-ish'"). Or with the twist keys around G (`TwistInput`) for a lovely tie-in: "Twist the knob to rotate the image upright".
  5. **"Select all squares containing the narrator":** all squares are empty. Verify with none → "He's everywhere. Correct."
- **Escalation:** classic → bulbs → twist; the desktop tilts 3° more with every failure (twist theme) and straightens when you pass.
- **Narrator:** "A machine asking you to prove you're not a machine. On a machine." / Level 5: "I'm flattered."
- **Remove:** "close X after 3 s passes". Keep a close X, but closing re-opens the window with "Nice try, robot."
- **Scope:** M (levels are small; build 3 first) · **Visit:** 3.
- **[consult teammate]:** it changes their pass rule (random tries → deterministic) and the bot-button result.

### NEW 1: **Inky, the Helpful Assistant** (Clippy parody)
- **Hook:** an ink blot with googly eyes and a pen-nib hat living in the corner: "It looks like you're writing a comic! Would you like help?" [Yes] [Yes, please]. He's the in-computer foil to the narrator; they bicker (narrator: "I didn't approve him.").
- **Controls:** click the bubbles. The minigame is **getting rid of him**: he dodges the close X, hides behind windows, and reappears in a different corner. Drag him into the Recycle Bin (the bin spits him out once), then he leaves on his own when you "rate him 5 stars".
- **Escalation:** 1) an annoying helpful tip; 2) he "helps": autocorrects your document into nonsense ("lights" → "lies"), and you click the words to undo; 3) twist: he offers "Turn on Night Mode for your eyes?". Whatever you click, the screen dims to black → the visit 2 blackout. He caused it.
- **Narrator:** "Oh good, a mascot." / "He's not in my script." / "Inky, no."
- **Scope:** M · **Visit:** 2 (finale); a cameo in 3 (Inky is now "Inky Premium" and costs $4.99).

### NEW 2: **Software Update** (the progress bar that won't)
- **Hook:** after the power cut, the computer must "install updates before you can continue". A progress bar.
- **Controls:** mostly waiting, but the player can **help**: click "Speed up" (it slows down), shake the window (it goes faster, a fun physical toy), or twist the bar's dial with the twist keys.
- **Escalation:** 1) normal, 0 → 63%; 2) it goes **backwards** to 12% ("Rolling back changes..."), with silly step texts ("Reticulating comics", "Unplugging the sun", "Downloading more Comic Sans"); 3) it reaches 99% and stops. "Shaking" the window makes the 1% fall out of the bar onto the desktop; drag it back in → 100%.
- **Narrator:** "Updates. The only thing in this office that works overtime besides you." / At 99%: "Just a little more." (repeats exactly 3 times, then: "I'm out of encouragement.")
- **Scope:** S · **Visit:** 2 (opener).

### NEW 3: **Sleep vs Bank Balance** (plan: "sleep money reduce")
- **Hook:** Stop menu → **Sleep**, or a big "💤 Take a nap" desktop icon. The narrator dares you.
- **Controls:** hold the Sleep button to sleep; the screen darkens (light theme) and the bank balance ticker in the tray drains: "$1,204.17 → $1,203.02...". Release to wake.
- **Escalation:** 1) a short nap costs $3 ("Unpaid break"); 2) a longer nap shows dream bubbles: comic panels of the stand-up career you never had; 3) holding for 10 s gives a "BANK ACCOUNT: −$∞" and the narrator wakes you: "Fine. You're fired. Kidding. You can't be fired, you're not salaried." It's optional content; it never blocks.
- **Narrator:** "Go on. Sleep. I'll narrate the silence." / "That nap cost you a sandwich."
- **Scope:** S · **Visit:** 2 or 3 (optional desktop gag, always available after visit 1).

### NEW 4: **Password Expired** (Password Game parody)
- **Hook:** visit 3 starts with "Your password has expired. Choose a new one." A live rules list (green ✓ / red ✗), Password-Game style, themed on our jams.
- **Controls:** typing in one field; rules update live.
- **Rules (escalating, rule-of-three then derail):** 1) at least 8 characters; 2) a number; 3) an uppercase letter; 4) "must contain the name of a comic font"; 5) "must contain a light source (💡, sun, lamp, candle)"; 6) "must not contain the letter 'e' (budget cuts)" (conflicts with "Comic Neue" and "Comic Relief"; the only comic font without an 'e' is "Comic Shanns Mono", which is a nice little puzzle); 7) "must be your old password, twisted" (reversed; we stored it in visit 1); 8) final: the input field's font becomes Wingdings, and the narrator says "Accepted. I'm not checking any more."
- **Narrator:** "IT's password policy was written by a man who has been awake since 2003." / On the reversed-password rule: "We stored your old password in plain text. Obviously."
- **Scope:** M (rule checks are simple string functions) · **Visit:** 3 (opener).

### NEW 5: **Exit Vim** (plan: "restart power to exit vim"; reuses the teammate's vim editor)
- **Hook:** IT "upgraded" Comic Writer, and the document now opens in **vim**: exactly the teammate's current vim screen, now as a *window* in the desktop (their work becomes a joke instead of being thrown away). The goal: close it to save the document.
- **Controls:** keyboard. Real vim exit attempts (`:q`, `:wq`, `:q!`, `ZZ`, Esc spam) each get a response; the close X says "Unsaved changes. Also, this is vim."
- **Escalation:** 1) `:q` → "E37: No write since last change" (real); 2) `:wq` → "E212: Can't open file for writing: Comic font required"; 3) every attempt makes the window bigger until it covers the desktop. Inky: "It looks like you're trying to exit vim. Nobody has ever done that." The narrator finally: "There's only one way out of vim. Everyone knows that." The **Power** button on the monitor (the teammate's existing button, kept!) is the answer. Pressing it causes the visit 3 **blackout**; the player did it.
- **Narrator:** "Ah, vim. The editor you can check into but never leave." / On `:q!`: "Exclamation marks won't help. I've tried."
- **Scope:** M · **Visit:** 3 (finale).
- **[consult teammate]:** this keeps their editor code, just framed as a gag; they may want to own it.

### NEW 6: **Twisted Text** (plan: "letters/words keep floating around and you need to drag them back")
- **Hook:** your comic script's words come loose and float off, twisting, from the light flicker. Drag them back into their slots.
- **Controls:** drag-and-drop words, or select a word and twist it upright with the B-H-Y-T-F-V keys (`TwistInput`), which ties the computer to the switch minigames' signature input.
- **Escalation:** 1) three words drift; drag back; 2) the letters inside words twist (anagrams: "LIGHTS" → "SLIGHT"); twist them right; 3) a whole sentence turns upside down (like room C2); the fix is to rotate the monitor itself (the window rotates 180°).
- **Narrator:** "Your words are getting away from you. Relatable." / On an anagram: "Plot twist. Literally."
- **Scope:** M · **Visit:** 2 or 3 (good mid-visit filler).

### NEW 7 (optional, cheap): **Side Monitor** (plan: "side monitor with Bee Movie and Subway Surfers")
- **Hook:** a second, smaller window ("FocusTube") autoplays a fake low-attention video: a hand-drawn endless runner loop and scrolling "Bee Movie script" text. It's a distraction that **steals the document's progress %** while visible.
- **Controls:** minimise it; it re-opens itself after 20 s, a little bigger each time.
- **Escalation:** 1) small, muted; 2) unmutes (a mouth-made beat); 3) it becomes the wallpaper. The narrator: "You can't focus without something else not to focus on."
- **Scope:** S (no licensed footage: draw it) · **Visit:** any; a background gag in visit 2 or 3.

(Also considered: a **printer jam** that needs a twist to clear, which overlaps with Twisted Text; a "very good button that keeps asking why", better as a desktop icon gag than a minigame.)

---

## 6. Proposed computer content per visit

Each visit ends with a blackout **caused from the computer** (rule of three, then derail: visit 1 an ad did it, visit 2 the assistant did it, visit 3 **you** did it).

| Visit | Queue (ids) | Ending → blackout | Length |
|---|---|---|---|
| **1** (fixed) | `mic_password` → `font_picker` → `ad_storm` | Eco Mode ad: "TURN OFF LIGHTS" | ~3 min |
| **2** (after switch 1) | `software_update` → `memo_mail` (corporate speak v2) → `inky` | Inky: "Night Mode for your eyes?" | ~3–4 min |
| **3** (after switch 2) | `password_expired` → `captcha_gauntlet` (bot check v2) → `exit_vim` | The player presses Power to exit vim | ~4 min |

Optional/ambient on visits 2–3: the Sleep gag (Stop menu), the Side Monitor, desktop icon gags, and Twisted Text as a filler between steps if a visit feels short. Wallpaper and clock change every visit (§3).

---

## 7. Implementation plan

### Keep vs change in the teammate's framework
**Keep (as is):** `Minigame` base (`begin/cleanup/complete/fail`, `request_spawn`), `MinigameConfig` + per-minigame `.tres`, `MinigameRegistry`, `Computer.start_minigame`/`active_minigames`/`add_score`/`buffer`, `Computer.open()/queue()`, `EventManager` step semantics (a step ends when its last instance is gone), and the `GameState` signals. Each visit beat maps to a registry id, so the story only edits `Story.FIRST/SECOND/THIRD_VISIT`.

**Change:**
- `computer.tscn` visuals: the fullscreen vim editor becomes a desktop + taskbar + windows; the editor becomes the **Comic Writer** app window (it keeps the `buffer` API and still exposes `computer.editor` as the rect to place pop-ups over). **[consult teammate]**
- The **Power** button stays (the visit 3 punchline), but on visits 1–2 pressing it gets a narrator line ("Turning it off and on again isn't a strategy. Yet.") and still exits, so free use works.
- Status bar `Score`: either hide it, or reframe it as the **document progress %** / bank balance. **[consult teammate]** about what score was meant for.
- A new reusable `AppWindow` (title bar, close/min, drag, pop in/out, close-burst word). Minigames put their content inside it instead of a bare panel. Existing scenes can migrate one by one.
- A blackout from inside the computer: a new `Computer.blackout()` (screen flicker → CRT-off → `GameState.set_power(false)` → fade to the office). `StoryStage` must then accept "power already off" in a switch step (currently it turns it off 1.5 s after load: just skip that and play the cue).
- New ids (`mic_password`, `font_picker`, `ad_storm`, ...) in `minigame_registry.tres`.

### Tasks (one feature per subagent)
| # | Task | Size | Depends on | Notes |
|---|---|---|---|---|
| T1 | **Comic UI kit**: `AppWindow` component (outline, title bar, X/min, drag, squash-and-stretch open/close, close-burst words "POOF!"), comic theme variations (paper body, thick borders), halftone shader for backgrounds, glove cursor | M | — | Pure addition, no teammate code touched |
| T2 | **ComicOS desktop** in `computer.tscn`: wallpaper, icons, taskbar (Stop menu, open apps, tray, clock), notification toasts; the editor → Comic Writer window using `GameState.document_font`; Power-button lines | L | T1 | **[consult teammate]** before merging; keep `Computer` API unchanged |
| T3 | **Computer blackout + story wiring**: `Computer.blackout()` (flicker, CRT-off, `set_power(false)`, return to the office); `StoryStage` handles power already off; `Story.FIRST_VISIT = [mic_password, font_picker, ad_storm]`; `exit_when_done` off for blackout endings | S | — (T2 for looks) | Our code (Story, StoryStage) |
| T4 | **`mic_password`**: `enable_input`, muted `Mic` bus + `AudioEffectCapture`, live waveform, voice-activity detection, 5 scripted fails, silent-timeout path, fake-waveform fallback, text box, `GameState.password`; macOS preset `privacy/microphone_usage_description` + `codesign/entitlements/audio_input` | M | T1 | Test on an export with permission granted *and* denied |
| T5 | **`font_picker`**: list with `SystemFont` previews, escalating wrong-pick lines, renaming twist animation, Comic Sans licence gag, sets `GameState.document_font` | S–M | T1 | |
| T6 | **`ad_storm`** + ad variants: wave controller (keypress/idle triggers, spawns `ad_popup` via `computer.start_minigame`, caps the window count), Emily-is-Away scripted typing in Comic Writer, ad skins, Runner/Matryoshka/Fake X/Countdown/Eco Mode variants; Eco Mode → `Computer.blackout()` | M | T1, T3 (T2 for the Writer) | **[consult teammate]** for the `ad_popup` config fields |
| T7 | **Narration placeholders**: subtitle-only `NarratorCue`s for every line in §4–5 (`game/narration/computer_*.tres`), `once` where noted; idle and refusal lines | S | — | Can run in parallel from day one |
| T8 | **`software_update`** | S | T1 | |
| T9 | **`memo_mail`** (corporate speak v2: boss mood meter, 3 emails, Reply All) | M | T1 | **[consult teammate]**: extends their scene and sentence format |
| T10 | **`inky`** assistant (dodging, bin, autocorrect gag, Night Mode → blackout) | M | T1, T3 | |
| T11 | Visit 2 wiring (`Story.SECOND_VISIT`, wallpaper v2, clock) | S | T8–T10 | |
| T12 | **`password_expired`** (live rules list, uses `GameState.password`) | M | T1, T4 | |
| T13 | **`captcha_gauntlet`** (bot check v2: deterministic classic level + bulbs + twisted letters [+ circle/narrator levels]); desktop tilt on failure | M | T1 | **[consult teammate]**: changes their pass rule |
| T14 | **`exit_vim`** (the teammate's editor in a window, vim exit responses, growing window, Power → blackout) | M | T2, T3 | **[consult teammate]**: they may want to own it |
| T15 | Visit 3 wiring (`Story.THIRD_VISIT`, wallpaper v3) | S | T12–T14 | |
| T16 | Optional desktop gags: Sleep vs Bank Balance, Side Monitor, DO NOT CLICK.exe, Twisted Text | S each (Twisted Text M) | T2 | Only if time allows |
| T17 | Comic juice pass: mouth-made SFX recorded by the team (pops, boings, "pew"), onomatopoeia on every close, screen-shake helper | S | T1 | Team records; agent wires up |

**Critical path for visit 1:** T1 → (T4, T5, T6 in parallel) → T3 wiring, with T7 alongside. T2 (the full desktop) can land after visit 1 is playable, because the visit-1 apps work over the current screen as long as they use `AppWindow`.

**Questions for the teammate:** (1) Are you still changing `computer.tscn`, `ad_popup` or `bot_check` on your branch? (2) What did you intend `Score` to become? (3) Do you want to own the vim gag (T14) or the corporate-speak rework (T9)? (4) OK to move the editor into a window and the vim look into visit 3?
