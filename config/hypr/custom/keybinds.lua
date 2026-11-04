-- ============================================================================
--  Пользовательские хоткеи — порт из MangoWC (config/mango/config.conf)
--
--  Файл загружается последним, поэтому может переопределять дефолтные бинды
--  end-4. Для конфликтующих клавиш сначала снимаем старый бинд через hl.unbind(),
--  иначе Hyprland выполнит оба действия.
-- ============================================================================

-- Редактирование этого файла
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "Edit user keybinds" })

--##! Переопределения дефолтных биндов end-4 (приоритет Mango)
hl.unbind("SUPER + S")    -- было: scratchpad
hl.unbind("SUPER + M")    -- было: панель медиа
hl.unbind("SUPER + Tab")  -- было: обзор (overview)
hl.unbind("SUPER + G")    -- было: overlay виджетов
hl.unbind("SUPER + O")    -- было: левый сайдбар (дубль SUPER+A)
hl.unbind("Print")        -- было: скриншот в буфер обмена
hl.unbind("CTRL + Print") -- было: скриншот в файл

--##! Меню, приложения, обои
hl.bind("ALT + Space", hl.dsp.exec_cmd("rofi -show drun"), { description = "App: Rofi launcher" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("spotify-launcher"), { description = "App: Spotify" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("$HOME/.config/matugen/set-wallpaper.sh --pick"),
    { description = "App: Wallpaper picker" })

--##! Скриншоты (Print — область, CTRL+Print — весь экран)
hl.bind("Print", hl.dsp.exec_cmd("$HOME/.local/bin/screenshot region"),
    { locked = true, description = "Utilities: Screenshot region" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("$HOME/.local/bin/screenshot full"),
    { locked = true, description = "Utilities: Screenshot full screen" })

--##! Система
hl.bind("SUPER + R", hl.dsp.reload_config(), { description = "System: Reload Hyprland config" })
hl.bind("SUPER + M", hl.dsp.exit(), { description = "System: Exit Hyprland" })

--##! Окна
hl.bind("SUPER + Tab", hl.dsp.window.cycle_next(), { description = "Window: Cycle next" })
hl.bind("ALT + Tab", hl.dsp.focus({ last = true }), { description = "Window: Focus last" })
hl.bind("SUPER + Backslash", hl.dsp.window.float({ action = "toggle" }),
    { description = "Window: Toggle floating" })
hl.bind("ALT + A", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { description = "Window: Toggle maximize" })
hl.bind("ALT + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" }),
    { description = "Window: Fake fullscreen" })
hl.bind("SUPER + G", hl.dsp.window.pin(), { description = "Window: Pin (global, on all workspaces)" })
hl.bind("ALT + SHIFT + Return", hl.dsp.layout("togglesplit"),
    { description = "Window: Toggle split direction" })

-- Mango: NONE + btn_middle = togglemaximizescreen.
-- Внимание: бинд без модификаторов перехватывает среднюю кнопку мыши глобально.
hl.bind("mouse:274", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { mouse = true, description = "Window: Toggle maximize (middle click)" })

--##! Scratchpad (Mango: ALT+Z)
hl.bind("ALT + Z", hl.dsp.workspace.toggle_special("special"),
    { description = "Workspace: Toggle scratchpad" })

--##! Отправка окна на воркспейс с переходом (Mango: ALT+1..9 = tag)
for i = 1, 9 do
    hl.bind("ALT + " .. i, function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = true }))
    end, { description = "Window: Move to workspace " .. i .. " and follow" })
end

--##! Мониторы (Mango: ALT+SHIFT ←/→, SUPER+ALT ←/→)
hl.bind("ALT + SHIFT + Left", hl.dsp.focus({ monitor = "l" }), { description = "Monitor: Focus left" })
hl.bind("ALT + SHIFT + Right", hl.dsp.focus({ monitor = "r" }), { description = "Monitor: Focus right" })
hl.bind("SUPER + ALT + Left", hl.dsp.workspace.move({ monitor = "l" }),
    { description = "Monitor: Move workspace left" })
hl.bind("SUPER + ALT + Right", hl.dsp.workspace.move({ monitor = "r" }),
    { description = "Monitor: Move workspace right" })

--##! Зазоры (Mango: ALT+SHIFT+X/Z/R)
local gaps_in = hl.get_config("general:gaps_in") or 4
local gaps_out = hl.get_config("general:gaps_out") or 5
local gaps_backup = nil

hl.bind("ALT + SHIFT + X", function()
    gaps_in = gaps_in + 1
    gaps_out = gaps_out + 1
    hl.config({ general = { gaps_in = gaps_in, gaps_out = gaps_out } })
end, { repeating = true, description = "Gaps: Increase" })

hl.bind("ALT + SHIFT + Z", function()
    gaps_in = math.max(0, gaps_in - 1)
    gaps_out = math.max(0, gaps_out - 1)
    hl.config({ general = { gaps_in = gaps_in, gaps_out = gaps_out } })
end, { repeating = true, description = "Gaps: Decrease" })

hl.bind("ALT + SHIFT + R", function()
    if gaps_backup then
        gaps_in, gaps_out = gaps_backup[1], gaps_backup[2]
        gaps_backup = nil
    else
        gaps_backup = { gaps_in, gaps_out }
        gaps_in, gaps_out = 0, 0
    end
    hl.config({ general = { gaps_in = gaps_in, gaps_out = gaps_out } })
end, { description = "Gaps: Toggle" })

--##! Свободное перемещение и ресайз окна (Mango: movewin/resizewin, шаг 50px)
local move_step = 50
hl.bind("CTRL + SHIFT + Left", hl.dsp.window.move({ x = -move_step, y = 0, relative = true }),
    { repeating = true, description = "Window: Move left 50px" })
hl.bind("CTRL + SHIFT + Right", hl.dsp.window.move({ x = move_step, y = 0, relative = true }),
    { repeating = true, description = "Window: Move right 50px" })
hl.bind("CTRL + SHIFT + Up", hl.dsp.window.move({ x = 0, y = -move_step, relative = true }),
    { repeating = true, description = "Window: Move up 50px" })
hl.bind("CTRL + SHIFT + Down", hl.dsp.window.move({ x = 0, y = move_step, relative = true }),
    { repeating = true, description = "Window: Move down 50px" })

hl.bind("CTRL + ALT + Left", hl.dsp.window.resize({ x = -move_step, y = 0, relative = true }),
    { repeating = true, description = "Window: Resize left 50px" })
hl.bind("CTRL + ALT + Right", hl.dsp.window.resize({ x = move_step, y = 0, relative = true }),
    { repeating = true, description = "Window: Resize right 50px" })
hl.bind("CTRL + ALT + Up", hl.dsp.window.resize({ x = 0, y = -move_step, relative = true }),
    { repeating = true, description = "Window: Resize up 50px" })
hl.bind("CTRL + ALT + Down", hl.dsp.window.resize({ x = 0, y = move_step, relative = true }),
    { repeating = true, description = "Window: Resize down 50px" })

-- ============================================================================
--  Не перенесено (нет эквивалента в Hyprland / уже есть в end-4 по умолчанию)
--
--  Уже совпадает с end-4, ничего добавлять не нужно:
--    SUPER+Q (close), SUPER+F (fullscreen), SUPER+arrows (focus),
--    SUPER+SHIFT+arrows (move), SUPER+T/W/C/E (terminal/browser/editor/file manager),
--    SUPER+1..9 (workspaces), SUPER+SUPER (search), SUPER+mouse:272/273 (move/resize).
--
--  Mango-only, пропущено:
--    SUPER+I / SUPER+SHIFT+I   — minimize / restore (в Hyprland нет минимизации)
--    SUPER+N                   — switch_layout (оставлен правый сайдбар end-4)
--    ALT+E / ALT+X             — scroller: proportion / preset
--    ALT+SUPER+CTRL+arrows     — scroller stack
--    SUPER+O                   — toggleoverlay; заменён на overview (SUPER+O)
--    axis SUPER+scroll         — уже есть переключение воркспейсов в end-4
--    3/4-finger gestures       — в end-4 уже настроены (move/workspace/overview)
-- ============================================================================
