<p align="center">
  <img src="docs/branding/logo.png" width="112" alt="Siraj logo">
</p>

<h1 align="center">Siraj · سراج</h1>

<p align="center">
  <b>A free, open-source Muslim companion: Quran, 240+ reciters, hadith, prayer times and gentle reminders through the day.</b><br>
  No ads. No account. No tracking. Works offline.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.32-02569B?logo=flutter">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-0E5A49">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-D5B26C">
</p>

## Screenshots

| Home | Mushaf | Follow the recitation |
|:---:|:---:|:---:|
| <img src="docs/screenshots/01_home.png" width="260"> | <img src="docs/screenshots/02_reader.png" width="260"> | <img src="docs/screenshots/03_player.png" width="260"> |
| **Hadith & Sunnah** | **Hadith** | **Daily reminders** |
| <img src="docs/screenshots/04_hadith.png" width="260"> | <img src="docs/screenshots/05_hadith_detail.png" width="260"> | <img src="docs/screenshots/06_reminders.png" width="260"> |
| **Listen to adhkar** | **Settings** | **Dark** |
| <img src="docs/screenshots/10_adhkar_listen.png" width="260"> | <img src="docs/screenshots/08_appearance.png" width="260"> | <img src="docs/screenshots/09_home_dark.png" width="260"> |
| **Memorization test** | | |
| <img src="docs/screenshots/12_memorize.png" width="260"> | | |

## Features

- **Mushaf.** The complete Madani Mushaf: 604 pages in the exact KFGQPC 15-line layout, fully offline, with smooth page
  turns. Search in Arabic and English. Translations: English (Saheeh International) and Somali.
- **Listen.** 243 reciters and 289 recitations (Hafs, Warsh, Qalun, Mujawwad…). Download one surah or the whole Quran,
  play in the background, and use ayah repeat for memorisation, a sleep timer and speed control.
- **Follow the recitation.** The player shows the whole surah and keeps the ayah being recited in view, exactly, for the
  111 recitations with ayah timing ("Ayah sync"; each checked against its audio). Tap any ayah to jump to it.
- **Hadith & Sunnah.** Sahih al-Bukhari, Sahih Muslim, Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah, Muwatta Malik,
  40 Nawawi, 40 Qudsi: Arabic, English and grades, searchable and offline. Includes 41 Sunnah practices with their
  sources.
- **Memorization test.** Test a surah, part of a surah or a juz: next ayah, previous ayah, complete the ayah, missing
  word, arrange the words, which surah, and recite from memory. Mistakes are listed for revision and can be practised
  again.
- **Daily reminders.** An ayah, a surah, a hadith, a sunnah or a dhikr every 1, 2, 3, 4, 6 or 8 hours, only during
  the hours you choose. Reminders follow the day: al-Kahf and salawat on Friday, fasting on Mondays and Thursdays, the
  White Days, Ramadan and its last ten nights, Dhul Hijjah, Arafah, Ashura, and morning, evening and bedtime adhkar.
  A separate reminder at the times you choose to read the morning and evening adhkar.
- **Prayer times & Qibla.** Calculated on the phone, with 11 methods, Hanafi/Standard Asr, prayer alerts and a Qibla
  compass.
- **Adhkar & tasbih.** Hisn al-Muslim in 8 categories, with tap-to-count cards and a tasbih counter. Listen to a whole
  category: each dhikr is recited by a human voice, repeated as many times as prescribed while the counter counts
  down, then the next one begins. Quranic adhkar are recited by Mishary Alafasy. The recordings ship with the app,
  so listening works offline. Tap any card to jump to it; tap the card being recited to count it.
- **Appearance.** Light, Dark and true-black Midnight themes. The Mushaf page colour (Ivory, White, Sepia, Dark, Black)
  can differ, and everything on the reading screen takes the page colour.
- **Private.** No account, no ads, no analytics. Bookmarks, history and downloads stay on the device.

## Build

```bash
flutter pub get
flutter run                 # Android device/emulator or iOS simulator
flutter test                # unit tests, Mushaf page goldens, renderer benchmark
flutter build apk --release --split-per-abi
```

Bundled content can be rebuilt with the scripts in `tool/` (Python 3 with Pillow and NumPy):

```bash
python tool/build_quran_db.py   # Quran text, Mushaf layout, translations -> assets/db/quran.db
python tool/build_hadith.py     # hadith catalog, 40-hadith books, Sunnah reminders -> assets/db/hadith.db
python tool/build_catalog.py    # reciters -> assets/catalog/reciters.json
python tool/scan_vbr.py         # variable-bitrate recitations (accurate seeking) -> assets/catalog/vbr.json
python tool/build_adhkar.py     # Hisn al-Muslim adhkar -> assets/adhkar/adhkar.json
python tool/build_adhkar_audio.py  # a verified recording cut for each dhikr -> assets/adhkar/audio.json (faster-whisper)
python tool/make_icons.py       # app icon, splash and logo from the mosque lamp photograph
```

## Project structure

```
lib/
  core/       quran db, hadith, reminders (Hijri-aware), notifications, audio, downloads, prayer, settings
  design/     tokens (Light / Dark / Midnight + Mushaf paper), theme, shared widgets
  features/   home, quran_index, reader (Mushaf renderer), player, reciters, hadith, daily, library, search, settings
  app/        app, router, tab shell, notification routing
tool/         build-time content scripts
docs/         product, design and architecture notes
```

## Contributing

Contributions are welcome: bug reports, translations of the interface, new translations of the Quran, accessibility
fixes and code. Please open an issue first for larger changes. Treat the religious content with care: every hadith
shown comes from the source collections with its reference and grade.

## Sources & licenses

- Quran text and Uthmanic Hafs font: King Fahd Glorious Quran Printing Complex (KFGQPC). Page layout via Quran.com.
- Translations: Saheeh International; Mahmud Muhammad Abduh (Somali).
- Recitations and ayah timings: [mp3quran.net](https://mp3quran.net), streamed from their servers.
- Hadith: [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) (public domain).
- Adhkar: Hisn al-Muslim. Adhkar recordings: [hisnmuslim.com](https://www.hisnmuslim.com) and, for Quranic adhkar,
  Mishary Alafasy via [everyayah.com](https://everyayah.com); cut to each dhikr and included for offline listening
  (`tool/build_adhkar_audio.py`, needs ffmpeg and faster-whisper). Prayer times: the open-source Adhan library. Hijri dates: Umm al-Qura.
- Fonts: IBM Plex Sans Arabic and Amiri (SIL Open Font License).
- Logo: a Mamluk enamelled glass mosque lamp, 14th century, photographed by The Metropolitan Museum of Art (Open
  Access, CC0; "Mosque Lamp MET DP332337" on Wikimedia Commons). Lamps like it carry the Verse of Light (24:35).

The app code is released under the [MIT License](LICENSE). Bundled content keeps its own terms.
