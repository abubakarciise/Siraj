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

> *Siraj* means "lamp". In the Quran (33:46) the Prophet ﷺ is called *sirājan munīrā*, "a light-giving lamp".

## Screenshots

| Home | Mushaf | Follow the recitation |
|:---:|:---:|:---:|
| <img src="docs/screenshots/01_home.png" width="260"> | <img src="docs/screenshots/02_reader.png" width="260"> | <img src="docs/screenshots/03_player.png" width="260"> |
| **Hadith & Sunnah** | **Hadith** | **Daily reminders** |
| <img src="docs/screenshots/04_hadith.png" width="260"> | <img src="docs/screenshots/05_hadith_detail.png" width="260"> | <img src="docs/screenshots/06_reminders.png" width="260"> |
| **Reminder sounds** | **Appearance** | **Dark** |
| <img src="docs/screenshots/07_sounds.png" width="260"> | <img src="docs/screenshots/08_appearance.png" width="260"> | <img src="docs/screenshots/09_home_dark.png" width="260"> |

## Features

- **Mushaf.** The complete Madani Mushaf: 604 pages in the exact KFGQPC 15-line layout, fully offline, with smooth page
  turns. Search in Arabic and English. Translations: English (Saheeh International) and Somali.
- **Listen.** 243 reciters and 289 recitations (Hafs, Warsh, Qalun, Mujawwad…). Download one surah or the whole Quran,
  play in the background, and use ayah repeat for memorisation, a sleep timer and speed control.
- **Follow the recitation.** The player shows the whole surah and keeps the ayah being recited in view. It is exact for
  reciters with timing data and estimated for the rest. Tap any ayah to jump to it.
- **Hadith & Sunnah.** Sahih al-Bukhari, Sahih Muslim, Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah, Muwatta Malik,
  40 Nawawi, 40 Qudsi: Arabic, English and grades, searchable and offline. Includes a hadith of the day and 41 Sunnah
  practices with their sources.
- **Daily reminders.** An ayah, a surah, a hadith, a sunnah or a dhikr every 1, 2, 3, 4, 6 or 8 hours, only during
  the hours you choose. Reminders follow the day: al-Kahf and salawat on Friday, fasting on Mondays and Thursdays, the
  White Days, Ramadan and its last ten nights, Dhul Hijjah, Arafah, Ashura, and morning, evening and bedtime adhkar.
- **Prayer times & Qibla.** Calculated on the phone, with 11 methods, Hanafi/Standard Asr, and prayer alerts.
- **Your sounds.** Choose the sound for each kind of reminder: original built-in sounds, your phone's default, silent,
  or any sound on your phone.
- **Adhkar & tasbih.** Hisn al-Muslim in 8 categories, with tap-to-count cards and a tasbih counter.
- **Appearance.** Light, Dark and true-black Midnight themes, with the Mushaf page colour set separately (Ivory, White,
  Sepia, Dark, Black).
- **Private.** No account, no ads, no analytics. Bookmarks, history and downloads stay on the device.

## Build

```bash
flutter pub get
flutter run                 # Android device/emulator or iOS simulator
flutter test                # unit tests, Mushaf page goldens, renderer benchmark
flutter build apk --release --split-per-abi
```

Bundled content can be rebuilt with the scripts in `tool/` (Python 3 with Pillow, NumPy and SciPy):

```bash
python tool/build_quran_db.py   # Quran text, Mushaf layout, translations -> assets/db/quran.db
python tool/build_hadith.py     # hadith catalog, 40-hadith books, Sunnah reminders -> assets/db/hadith.db
python tool/build_catalog.py    # reciters -> assets/catalog/reciters.json
python tool/make_sounds.py      # reminder sounds -> assets/sounds, res/raw
python tool/make_icons.py       # app icon, splash and logo
```

## Project structure

```
lib/
  core/       quran db, hadith, reminders (Hijri-aware), notifications + sounds, audio, downloads, prayer, settings
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
- Adhkar: Hisn al-Muslim. Prayer times: the open-source Adhan library. Hijri dates: Umm al-Qura.
- Fonts: IBM Plex Sans Arabic and Amiri (SIL Open Font License).

The app code is released under the [MIT License](LICENSE). Bundled content keeps its own terms.
