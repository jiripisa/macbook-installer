# MacBook installer

Jeden příkaz, který z úplně nového MacBooku udělá počítač připravený na
programování: terminál, editory, programovací jazyky, Git a GitHub.

## Než začneš

- Mac je zapojený do nabíječky a připojený k internetu.
- Jsi přihlášený do svého účtu na Macu a ten účet je **administrátor**
  (první účet založený při zapnutí nového Macu administrátor je).
- Máš účet na [GitHubu](https://github.com) a znáš k němu heslo.
- Máš na to zhruba hodinu. Většinu času ale skript pracuje sám.

## Spuštění

1. Otevři **Terminál**: zmáčkni `⌘ Command` + `mezerník`, napiš `Terminál`
   a zmáčkni `Enter`.
2. Zkopíruj tenhle příkaz (celý řádek):

   ```
   curl -fsSL https://raw.githubusercontent.com/jiripisa/macbook-installer/main/install.sh | bash
   ```

3. Vlož ho do Terminálu (`⌘ Command` + `V`) a zmáčkni `Enter`.

## Na co se tě skript zeptá

Všechny otázky přijdou na začátku, pak už skript běží sám:

1. **Heslo k Macu**: to, kterým se přihlašuješ. Při psaní se nic nezobrazuje,
   to je v pořádku. Pak zmáčkni `Enter`.
2. **Přihlášení na GitHub**: asi po deseti minutách skript ukáže jednorázový
   kód a otevře prohlížeč. Přihlas se, opiš kód a povol přístup. Někdy se to
   zeptá ještě jednou kvůli SSH klíčům; postup je stejný.
3. **Jméno a e-mail pro Git**: skript je navrhne podle GitHubu. Když sedí,
   jen zmáčkni `Enter`.

## Co se nainstaluje

| Co | K čemu to je |
| --- | --- |
| Ghostty | terminál, ve kterém budeš pracovat |
| Zed, Visual Studio Code | editory kódu |
| Google Chrome | prohlížeč (když už ho máš, skript ho jen převezme) |
| OrbStack | kontejnery (Docker) a linuxové virtuály |
| Claude Code | AI asistent pro programování v terminálu |
| Java, Maven, Node.js, Python, Go, Rust | programovací jazyky (spravuje je `mise`) |
| Flutter, CocoaPods | aplikace pro iPhone |
| xcodegen, xcbeautify, swiftformat, swiftlint | aplikace pro Mac a iPhone z terminálu |
| git, gh, lazygit, delta | Git a GitHub |
| starship, fzf, zoxide, eza, bat, ripgrep, fd, jq, micro, … | šikovné nástroje do terminálu |

Skript taky vytvoří SSH klíč, přidá ho na tvůj GitHub a nastaví terminál
(barevný prompt, našeptávání příkazů, hledání v historii šipkami).

## Po instalaci

Na konci skript vypíše, co zbývá udělat ručně. Obvykle je to tohle:

1. **Zavři Terminál a otevři Ghostty**, odteď pracuj v něm.
2. **Nainstaluj Xcode** z App Store (vyhledej „Xcode“, je zdarma a má přes
   10 GB). Až bude nainstalovaný, **spusť instalační příkaz znovu**: nastaví
   Xcode pro práci z terminálu a stáhne simulátor iPhonu.
3. **Přihlas se do Claude Code**: v Ghostty napiš `claude`.
4. **Zkontroluj Flutter**: v Ghostty napiš `flutter doctor`.

## Aktualizace

Stačí znovu spustit stejný příkaz. Doinstaluje, co chybí, a aktualizuje
všechno, co je zastaralé. Klidně ho spouštěj opakovaně, nic se nerozbije.

## Vlastní nastavení

Tyhle soubory spravuje skript a při dalším spuštění je přepíše:
`~/.zshrc`, `~/.zprofile`, `~/.config/starship.toml`,
`~/.config/ghostty/config`, `~/.gitignore_global` a
`~/.config/mise/conf.d/macbook-installer.toml`. Když se od verze ve skriptu
liší, původní verzi nejdřív zazálohuje vedle (`….backup-datum-čas`).

Tvoje vlastní věci patří jinam, tam je skript nikdy nepřepíše:

- aliasy a nastavení shellu do **`~/.zshrc.local`**,
- jiné verze jazyků přes `mise use -g …` (zapisují se do
  `~/.config/mise/config.toml`),
- další nastavení Gitu přes `git config --global …`.

## Když se něco pokazí

- Skript řekne, ve kterém kroku se to stalo.
- Celý průběh je zapsaný v logu v `~/Library/Logs/macbook-installer/`.
- Zkus příkaz spustit znovu. Když to nepomůže, ukaž log tátovi.

---

## Pro vývojáře

Testy (shellcheck + [bats](https://github.com/bats-core/bats-core)) běží proti
falešným příkazům v `tests/stubs` a dočasnému `HOME`, takže nic nemění na
skutečném počítači:

```
brew install shellcheck bats-core
make test
```

`setup.sh` nikdy nespouštěj naostro na svém Macu, přepsal by ti konfiguraci.
