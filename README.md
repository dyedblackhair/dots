# Dotfiles — MangoWC desktop

Мои конфиги для Wayland-десктопа на **MangoWC**: динамическая тема из обоев
(matugen), Waybar, Kitty, Rofi, Dunst, Cava, Zsh + Oh My Zsh.

## Состав

```
dotfiles/
├── install.sh              # установщик
├── packages.txt            # официальные пакеты Arch
├── packages-aur.txt        # AUR-пакеты (MangoWC, Waybar-git)
├── packages-apps.txt       # необязательные приложения (--apps)
├── config/                 # → ~/.config/*
│   ├── mango/              # config.conf (тема генерируется matugen)
│   ├── waybar/             # config.jsonc + scripts/
│   ├── kitty/              # kitty.conf (тема из matugen)
│   ├── rofi/               # config.rasi + tokyo.rasi
│   ├── cava/               # config, темы и шейдеры
│   ├── matugen/            # config.toml, apply.sh, set-wallpaper.sh, templates/
│   │                       #   (в templates/ — dunst, gtk, kde, kitty, mango, rofi, waybar)
│   ├── gtk-3.0/, gtk-4.0/  # настройки и шаблон gtk.css
│   ├── environment.d/      # GTK_THEME / QT_QPA_PLATFORMTHEME
│   └── hypr/custom/        # хоткеи для Hyprland (порт из Mango, см. ниже)
├── home/                   # → ~/
│   ├── .zshrc
│   └── .local/bin/screenshot
├── fallbacks/              # статичная тема, пока matugen не сгенерировал свою
└── wallpapers/11.jpg       # обои по умолчанию
```

## Установка

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

По умолчанию конфиги **симлинкуются** в `~/.config` и `~`: редактируешь файл
в репозитории — изменения сразу видны системе. Существующие файлы
перемещаются в `~/.dotfiles-backup/<дата-время>/`.

После установки выйди из сессии и выбери **Mango** в меню входа.

### Опции

| Опция | Что делает |
|---|---|
| `--copy` | копировать конфиги вместо симлинков |
| `--no-packages` | не ставить пакеты, только разложить конфиги |
| `--apps` | доставить необязательные приложения (LibreWolf, VSCodium, Spotify, Dolphin) |
| `--no-oh-my-zsh` | не устанавливать Oh My Zsh и плагины |
| `--no-chsh` | не менять login shell |
| `--no-theme` | не генерировать тему matugen |
| `--dry-run` | показать действия без изменений |
| `--uninstall` | удалить симлинки, указывающие в репозиторий |

## Что делает установщик

1. Ставит пакеты из `packages.txt` (pacman) и `packages-aur.txt` (yay/paru).
2. Ставит Oh My Zsh и плагины `zsh-autosuggestions`, `zsh-syntax-highlighting`
   (использует системные пакеты из `/usr/share/zsh/plugins`, если они есть).
3. Раскладывает конфиги, делая бэкап старого.
4. Кладёт обои в `~/Pictures/wallpaper/` и ставит тему из них через matugen.
5. Добавляет fallback-тему, если matugen ещё не запускался.
6. Меняет login shell на zsh.

### Шаблоны

В `@HOME@` содержат пути только два файла:

- `config/mango/config.conf`
- `config/waybar/config.jsonc`

При установке `@HOME@` заменяется на реальный `$HOME`, поэтому такие файлы
копируются, а не симлинкуются. Всё остальное использует `~` или `$HOME`.

## Динамическая тема

Тема строится из текущих обоев:

- `~/.config/matugen/set-wallpaper.sh --pick` — выбрать обои в Rofi
  (биндинг `Super+Shift+W`);
- `~/.config/matugen/set-wallpaper.sh --random` — случайные обои;
- `~/.config/matugen/apply.sh` — перегенерировать тему для текущих обоев.

Matugen обновляет Kitty, Waybar, Rofi, Dunst, GTK, KDE/Qt и цвета MangoWC.
Шаблоны лежат в `config/matugen/templates/`.

## Горячие клавиши Mango

| Клавиши | Действие |
|---|---|
| `Super+T` | Kitty |
| `Alt+Space` | Rofi (запуск приложений) |
| `Super+E` | Dolphin |
| `Super+W` | LibreWolf |
| `Super+C` | VSCodium |
| `Super+Shift+W` | выбор обоев |
| `Print` / `Ctrl+Print` | скриншот области / всего экрана |
| `Super+Q` | закрыть окно |
| `Super+M` | выход |
| `Super+1..9` | переключение тегов |
| `Alt+1..9` | перенести окно на тег |

Полный список — в `config/mango/config.conf`.

## Горячие клавиши Hyprland

Хоткеи из Mango перенесены в конфиг
[dots-hyprland](https://github.com/end-4/dots-hyprland):

```
config/hypr/custom/keybinds.lua   # → ~/.config/hypr/custom/keybinds.lua
```

Файл загружается последним и переопределяет дефолтные бинды end-4. Чтобы
поставить его, скопируй (или симлинкни) в `~/.config/hypr/custom/keybinds.lua`
и перезагрузи Hyprland (`Super+R` или `hyprctl reload`).

Что перенесено: запуск приложений и Rofi (`Alt+Space`), Spotify (`Super+S`),
выбор обоев (`Super+Shift+W`), скриншоты (`Print` / `Ctrl+Print`), выход
(`Super+M`), reload (`Super+R`), переключение и перенос окон, scratchpad
(`Alt+Z`), перенос окна на воркспейс (`Alt+1..9`), мониторы, зазоры
(`Alt+Shift+X/Z/R`), свободное перемещение/ресайз окна (`Ctrl+Shift+...`,
`Ctrl+Alt+...`), maximize средней кнопкой мыши.

Mango-only действия (scroller, minimize, switch_layout, toggleoverlay) и
жесты не переносились — список с пояснениями есть в конце файла.


## Полезно

- Лог matugen: `~/.cache/matugen/theme.log`
- Скриншоты: `~/Pictures/Screenshots`
- После правки `.zshrc`: `exec zsh`
- После правки конфига Mango: `Super+R` (reload_config), Waybar: `pkill -SIGUSR2 waybar`
