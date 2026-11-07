-- Window rules

hl.window_rule({ match = { class = "^$", title = "^$", xwayland = true, float = false, fullscreen = false, pin = false }, no_focus = true })
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ match = { class = ".*" }, opacity = "0.97 0.9" })
-- Affinity's File/Document menus are Xwayland popups. Blur plus the global
-- inactive opacity leaves them blank until the pointer moves. This rule is
-- after the global opacity rule so it wins. Do not hide empty titles:
-- those windows are the menus.
hl.window_rule({ match = { class = "^affinity\\.exe$", title = "^Affinity$" }, workspace = 8 })
hl.window_rule({ match = { title = "^affinity - Wine Desktop$" }, workspace = 8 })
hl.window_rule({ match = { class = "^affinity\\.exe$" }, no_blur = true })
hl.window_rule({ match = { class = "^affinity\\.exe$" }, opaque = true })
hl.window_rule({ match = { class = "^affinity\\.exe$" }, opacity = "1 1" })
hl.window_rule({ match = { title = "^affinity - Wine Desktop$" }, no_blur = true })
hl.window_rule({ match = { title = "^affinity - Wine Desktop$" }, opaque = true })
hl.window_rule({ match = { title = "^affinity - Wine Desktop$" }, opacity = "1 1" })
-- Workspace switches leave this Xwayland window visible but without X input
-- focus, so it ignores the pointer. xfocus.sh puts the focus back.
local function focus_affinity_x11(w)
    if w == nil or (w.class or "") ~= "affinity.exe" then
        return
    end
    hl.exec_cmd(os.getenv("HOME") .. "/.local/share/affinity-wine/xfocus.sh")
end
hl.on("window.active", focus_affinity_x11)
hl.on("workspace.active", function()
    focus_affinity_x11(hl.get_active_window())
end)
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.window_rule({ match = { tag = "floating-window" }, float = true })
hl.window_rule({ match = { tag = "floating-window" }, center = true })
hl.window_rule({ match = { tag = "floating-window" }, size = { 610, 500 } })
hl.window_rule({ match = { class = "(blueman-manager|org\\.blueman\\.Manager|bluetooth-window|localsend|Wiremix|nmgui)" }, tag = "+floating-window" })
hl.window_rule({ match = { title = "^Bluetooth Devices$" }, tag = "+floating-window" })
hl.window_rule({ match = { title = "^(.*Network Manager.*)$" }, tag = "+floating-window" })
hl.window_rule({ match = { title = "(webapp-install|share)" }, tag = "+floating-window" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)", title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)" }, tag = "+floating-window" })
hl.window_rule({ match = { title = "hyprluggage-tui" }, float = true })
hl.window_rule({ match = { title = "hyprluggage-tui" }, center = true })
hl.window_rule({ match = { title = "hyprluggage-tui" }, size = { 720, 580 } })
-- Calculator (hyprmath)
hl.window_rule({ match = { title = "hyprluggage-calc" }, float = true })
hl.window_rule({ match = { title = "hyprluggage-calc" }, center = true })
hl.window_rule({ match = { title = "hyprluggage-calc" }, size = { 560, 700 } })
hl.window_rule({ match = { title = "hyprluggage-browse" }, float = true })
hl.window_rule({ match = { title = "hyprluggage-browse" }, center = true })
hl.window_rule({ match = { title = "hyprluggage-browse" }, size = { 1200, 750 } })
hl.window_rule({ match = { class = "com.github.wwmm.easyeffects" }, float = true })
hl.window_rule({ match = { class = "com.github.wwmm.easyeffects" }, center = true })
hl.window_rule({ match = { class = "com.github.wwmm.easyeffects" }, size = { 950, 850 } })
-- Satty, the SUPER+P screenshot editor. Leave size unset so the window
-- matches the capture; a fixed size would crop the annotation canvas.
hl.window_rule({
    match = { class = "^com\\.gabm\\.satty$" },
    float = true,
    center = true,
    opacity = "1 1",
})
-- Fullscreen + float only. center left a default-sized Alacritty when the
-- fullscreen effect raced Alacritty's fork; screensaver-launch forces FS after map.
hl.window_rule({ match = { class = "Screensaver" }, fullscreen = true })
hl.window_rule({ match = { class = "Screensaver" }, float = true })
hl.window_rule({ match = { class = "^(Bitwarden)$" }, no_screen_share = true })
hl.window_rule({ match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)" }, tag = "+chromium-based-browser" })
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" }, tag = "+firefox-based-browser" })
hl.window_rule({ match = { tag = "chromium-based-browser" }, tile = true })
-- Bitwarden extension popup (passkeys).
-- Class is <browser>-<extension id>-<profile>, e.g. brave-nngceckbapebfimnlniiiahkandclblb-Default.
-- initialTitle is _crx_<extension id>. Regexes are full matches, so the id alone never matches.
local bitwarden_popup = {
    float = true,
    center = true,
    size = { 420, 680 },
    stay_focused = true,
}
hl.window_rule({
    match = { class = ".*nngceckbapebfimnlniiiahkandclblb.*" },
    float = bitwarden_popup.float,
    center = bitwarden_popup.center,
    size = bitwarden_popup.size,
    stay_focused = bitwarden_popup.stay_focused,
})
hl.window_rule({
    match = { initial_title = "^_crx_nngceckbapebfimnlniiiahkandclblb.*" },
    float = bitwarden_popup.float,
    center = bitwarden_popup.center,
    size = bitwarden_popup.size,
    stay_focused = bitwarden_popup.stay_focused,
})

-- Chromium may report the popup as the browser itself until the extension class is set.
-- Float is static, so a late class change would otherwise leave it tiled beside the page.
local function present_bitwarden_popup(w)
    if w == nil or w.floating then
        return
    end
    local class = w.class or ""
    local initial_class = w.initial_class or ""
    local initial_title = w.initial_title or ""
    local id = "nngceckbapebfimnlniiiahkandclblb"
    if not (class:find(id, 1, true) or initial_class:find(id, 1, true) or initial_title:find(id, 1, true)) then
        return
    end
    local window = "address:" .. w.address
    hl.dispatch(hl.dsp.window.float({ action = "on", window = window }))
    hl.dispatch(hl.dsp.window.resize({ x = 420, y = 680, relative = false, window = window }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
end

hl.on("window.open", present_bitwarden_popup)
hl.on("window.class", present_bitwarden_popup)
hl.on("window.title", present_bitwarden_popup)
hl.window_rule({ match = { tag = "chromium-based-browser" }, opacity = "1 0.97" })
hl.window_rule({ match = { tag = "firefox-based-browser" }, opacity = "1 0.97" })
hl.window_rule({ match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)" }, opacity = "1.0 1.0" })
hl.window_rule({ match = { title = "WebcamOverlay" }, float = true })
hl.window_rule({ match = { title = "WebcamOverlay" }, pin = true })
hl.window_rule({ match = { title = "WebcamOverlay" }, no_initial_focus = true })
hl.window_rule({ match = { title = "WebcamOverlay" }, no_dim = true })
hl.window_rule({ match = { title = "WebcamOverlay # There's a typo in the hyprland rule so 100%-w on the height param is actually correct here" }, move = "100%-w-40 100%-w-40" })
hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({ match = { tag = "pip" }, float = true })
hl.window_rule({ match = { tag = "pip" }, pin = true })
hl.window_rule({ match = { tag = "pip" }, size = { 600, 338 } })
hl.window_rule({ match = { tag = "pip" }, keep_aspect_ratio = true })
hl.window_rule({ match = { tag = "pip" }, border_size = 0 })
hl.window_rule({ match = { tag = "pip" }, opacity = "1 1" })
hl.window_rule({ match = { tag = "pip" }, move = "100%-w-40 4%" })
hl.window_rule({ match = { class = "^steam$ # use - hyprctl monitors - in terminal for list of monitors" }, monitor = "DP-1" })
hl.window_rule({ match = { class = "^steam_app_.*$" }, fullscreen = true })
-- Chat clients request activation on new messages. Ignore that request so they
-- stay in the background, but leave the windows focusable. no_focus makes
-- them impossible to click or type into.
local chat_apps = {
    "^telegram-desktop$",
    "^Telegram$",
    "^discord$",
    "^vesktop$",
    "^teams-for-linux$",
    "^Microsoft Teams$",
    "^Microsoft Teams - Preview$",
}
for _, class in ipairs(chat_apps) do
    hl.window_rule({ match = { class = class }, suppress_event = "activatefocus" })
end
hl.window_rule({ match = { class = "^(FreeCAD|freecad)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(steam_app_109600)$" }, fullscreen = true })
hl.window_rule({ match = { class = "^(steam_app_109600)$" }, float = true })
hl.window_rule({ match = { class = "^(steam_app_109600)$" }, size = { 3840, 2160 } })
hl.window_rule({ match = { class = "^(steam_app_109600)$" }, center = true })
hl.window_rule({ match = { title = "^(Cryptic.*)$" }, float = true })
