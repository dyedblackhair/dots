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
│   ├── waybar/             # config.jsonc (сеть, трей, Font Awesome) + scripts/
│   ├── dolphinrc           # настройки Dolphin (из dots-hyprland)
│   ├── kitty/              # kitty.conf (тема из matugen)
│   ├── rofi/               # config.rasi + tokyo.rasi
│   ├── cava/               # config, темы и шейдеры
│   ├── matugen/            # config.toml, apply.sh, set-wallpaper.sh, templates/
│   │                       #   (в templates/ — dunst, gtk, kde, kitty, mango, rofi, waybar)
│   ├── gtk-3.0/, gtk-4.0/  # настройки и шаблон gtk.css
│   └── environment.d/      # GTK_THEME / QT_QPA_PLATFORMTHEME
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

## Waybar и Dolphin

- Waybar использует **Google Sans** и иконки **Font Awesome**.
- В правой части бара: сеть (клик открывает `nmtui`), трей, громкость,
  яркость, батарея, часы, раскладка, уведомления, блокировка и питание.
- Трей: обычные иконки SNI + кнопка-меню (rofi) с быстрыми действиями.
- `config/dolphinrc` перенесён из dots-hyprland: полный путь в адресной
  строке, включённые превью, скрытая строка меню.

## Горячие клавиши Mango

Хоткеи собраны из [dots-hyprland](https://github.com/end-4/dots-hyprland)
(end-4) и переведены в синтаксис Mango. Quickshell-специфичные бинды
(сайдбар, медиапанель, эмодзи, читшит, экранная клавиатура, ИИ, OCR, запись
экрана) не переносились — в Mango для них нет эквивалентов.

### Система и приложения

| Клавиши | Действие |
|---|---|
| `Super+R` | перезагрузить конфиг Mango |
| `Super+M` | выход |
| `Super+Q` | закрыть окно |
| `Super+Shift+Alt+Q` | принудительно закрыть окно |
| `Ctrl+Alt+Delete` | меню питания (rofi) |
| `Super+L` | заблокировать (swaylock) |
| `Super+Shift+L` | сон |
| `Ctrl+Shift+Alt+Super+Delete` | выключение |
| `Alt+Space` | Rofi (запуск приложений) |
| `Super+Return` / `Super+T` | Kitty |
| `Ctrl+Alt+T` | Kitty |
| `Super+E` | Dolphin |
| `Super+W` | LibreWolf |
| `Super+C` | VSCodium |
| `Ctrl+Super+V` | pavucontrol |
| `Ctrl+Shift+Escape` | btop в Kitty |
| `Super+V` | история буфера обмена (cliphist + rofi) |
| `Super+J` | скрыть/показать Waybar |
| `Ctrl+Super+R` | перезапустить Waybar |

### Обои и тема

| Клавиши | Действие |
|---|---|
| `Super+Shift+W` / `Ctrl+Super+T` | выбрать обои |
| `Ctrl+Super+Alt+T` | случайные обои |

### Скриншоты и утилиты

| Клавиши | Действие |
|---|---|
| `Print` / `Ctrl+Print` | скриншот всего экрана |
| `Super+Shift+S` | скриншот области |
| `Super+Shift+C` | пипетка цвета (hyprpicker) |

### Окна

| Клавиши | Действие |
|---|---|
| `Super+←/→/↑/↓`, `Super+[` / `]` | фокус |
| `Super+Shift+←/→/↑/↓` | переместить окно |
| `Alt+Tab` | фокус на следующее окно |
| `Super+Alt+Space` / `Super+\` | плавающее окно |
| `Super+D` / `Alt+A` | maximize |
| `Super+F` | fullscreen |
| `Super+Alt+F` / `Alt+Shift+F` | fake fullscreen |
| `Super+P` / `Super+G` | pin (toggleglobal) |
| `Super+O` | overlay |
| `Super+I` / `Super+Shift+I` | minimize / restore |
| `Super+;` / `Super+'` | изменить ratio |
| `Alt+Shift+Return` | сменить направление сплита |
| `Ctrl+Super+\` | сбросить размер окна до 640×480 |
| `Super+Alt+←/→` | перенести окно на монитор |

### Теги, scratchpad, раскладки

| Клавиши | Действие |
|---|---|
| `Super+1..9` | переключить тег |
| `Super+Alt+1..9` | отправить окно на тег без перехода |
| `Alt+1..9` | отправить окно на тег и перейти |
| `Ctrl+Super+←/→` | предыдущий / следующий тег |
| `Super+Page_Up/Page_Down` | предыдущий / следующий тег |
| `Super+Shift+Page_Up/Page_Down` | перенести окно на соседний тег |
| `Super+S` / `Ctrl+Super+S` | показать/скрыть special-тег (scratchpad) |
| `Super+Alt+S` | отправить окно в special-тег |
| `Alt+Z` | обычный scratchpad |
| `Super+N` | сменить layout |
| `Super+Tab` | обзор (overview) |
| `Alt+Shift+←/→` | фокус на монитор |

### Медиа, зазоры, scroller

| Клавиши | Действие |
|---|---|
| `XF86Audio*` | громкость / mute / микрофон / плеер |
| `XF86MonBrightnessUp/Down` | яркость |
| `Super+Shift+N/B/P` | next / previous / play-pause |
| `Super+Shift+M` / `Super+Alt+M` | mute выхода / микрофона |
| `Alt+Shift+X/Z` | увеличить / уменьшить зазоры |
| `Alt+Shift+R` | включить/выключить зазоры |
| `Alt+E`, `Alt+X` | scroller: ratio / preset |
| `Ctrl+Alt+Super+←/→/↑/↓` | scroller: stack |

Полный список — в `config/mango/config.conf`.


## Полезно

- Лог matugen: `~/.cache/matugen/theme.log`
- Скриншоты: `~/Pictures/Screenshots`
- После правки `.zshrc`: `exec zsh`
- После правки конфига Mango: `Super+R` (reload_config), Waybar: `pkill -SIGUSR2 waybar`
