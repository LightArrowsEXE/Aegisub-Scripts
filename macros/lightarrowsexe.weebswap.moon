export script_name = "WeebSwap"
export script_description = "Swaps (partial) events in pairs based on a key"
export script_author = "lightarrowsexe"
export script_version = "1.0.0"
export script_namespace = "lightarrowsexe.weebswap"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/LightArrowsEXE/Aegisub-Scripts/main/DependencyControl.json"
}

last_styles_cache = {"All Styles"}

last_settings_defaults = {
    delimiter: "*"
    styles: "All"
}

last_settings = depctrl\getConfigHandler {
    namespace: script_namespace
    section: "last_settings"
    defaults: last_settings_defaults
}

last_settings\load!

defaultConfig =
    delimiter: "*"
    styles: "All"

config = depctrl\getConfigHandler {
    presets: { Default: {} }
    currentPreset: "Default"
}

config\write! unless config\load!

savePreset = (preset, res) ->
    preset\import res, nil, true

    if res.__class != DependencyControl.ConfigHandler
        for key, value in pairs res
            continue if key == "presetModify" or key == "presetSelect"

            preset.c[key] = value

    preset\write!

createNewPreset = (settings) ->
    msg = "Enter name of the preset:"

    while true
        guiString = "| label,msg                             |            |
                     | label, Preset Name                    | edit, name |
                     | check, setCurrent,Set as Current Name |            |"

        guiString = guiString\gsub "msg", msg

        btn, res = aegisub.dialog.display({
            {class: "label", label: msg, x: 0, y: 0, width: 2, height: 1},
            {class: "edit", name: "name", label: "Preset Name", x: 0, y: 1},
            {class: "checkbox", name: "setCurrent", label: "Set as Current Name", x: 0, y: 2}
        }, {"OK", "Cancel"})

        aegisub.cancel! unless btn == "OK"
        presetName = res.name

        if presetName == ""
            msg = "You left the name empty!"
        elseif presetName == "Default"
            msg = "Default preset already exists."
        elseif config.c.presets[presetName]
            msg = "There is already another preset of same name."
        else
            if res.setCurrent
                config.c.currentPreset = presetName
                config\write!

            preset = config\getSectionHandler {"presets", presetName}, defaultConfig
            savePreset preset, settings

            return presetName

get_styles = (subs) ->
    styles = {}
    for i = 1, #subs
        line = subs[i]
        if line.class == "style"
            styles[line.name] = true
    style_list = [k for k in pairs styles]
    table.sort style_list
    table.insert style_list, 1, "All Styles"
    style_list

configSetup = (presetName) ->
    config\load!

    if type(presetName) != "string"
        presetName = config.c.currentPreset

    presetNames = [key for key, _ in pairs config.c.presets]
    table.sort presetNames
    dropPreset = table.concat(presetNames, "::")..","..presetName
    preset = config\getSectionHandler {"presets", presetName}, defaultConfig

    -- Get styles from the current script
    subs = aegisub.get_subtitles and aegisub.get_subtitles! or {}
    style_items = #subs > 0 and get_styles(subs) or last_styles_cache

    guiString = {
        {class: "label", label: "Current Preset: #{config.c.currentPreset}", x: 0, y: 0, width: 2, height: 1},
        {class: "label", label: "Delimiter", x: 0, y: 1},
        {class: "edit", name: "delimiter", value: preset.c.delimiter, x: 1, y: 1},
        {class: "label", label: "Styles", x: 0, y: 2},
        {class: "dropdown", name: "styles", items: style_items, value: (preset.c.styles == "All" or not preset.c.styles) and "All Styles" or preset.c.styles, x: 1, y: 2},
        {class: "label", label: "Preset", x: 0, y: 3},
        {class: "dropdown", name: "presetSelect", items: presetNames, value: presetName, x: 1, y: 3},
        {class: "dropdown", name: "presetModify", items: {"Load", "Modify", "Delete", "Rename", "Set Current"}, value: "Load", x: 1, y: 4}
    }

    btn, res = aegisub.dialog.display(guiString, {"Modify Preset", "Create Preset", "Save Preset", "Cancel"})
    aegisub.cancel! unless btn and btn != "Cancel"

    if btn == "Create Preset"
        createNewPreset res
        configSetup!
    elseif btn == "Save Preset"
        savePreset preset, res
        configSetup!
    elseif btn == "Modify Preset"
        if presetName != res.presetSelect
            preset = config\getSectionHandler {"presets", res.presetSelect}, defaultConfig
            presetName = res.presetSelect

        switch res.presetModify
            when "Load"
                configSetup presetName
            when "Set Current"
                config.c.currentPreset = presetName
                config\write!
                return

        assert res.presetSelect != "Default", "You probably should not modify the default preset. Create a new custom preset instead."

        switch res.presetModify
            when "Delete"
                config.c.currentPreset = "Default"
                config\write!
                preset\delete!
            when "Modify"
                savePreset preset, res
            when "Rename"
                presetName = createNewPreset preset.userConfig
                preset\delete!

        configSetup!

update_styles_cache = (subs) ->
    last_styles_cache = get_styles(subs)

build_dialog = (subs, settings) ->
    style_items = get_styles(subs)
    {
        {class: "label", label: "Delimiter: The text inside the curly braces to swap, e.g. * for {*}", x: 0, y: 0, width: 4, height: 1}
        {class: "edit", name: "delimiter", label: "Delimiter (for in-line swaps)", value: settings.delimiter or last_settings_defaults.delimiter, x: 0, y: 1}
        {class: "label", label: "Style: Only lines with this style (or regex) will be affected for in-line swaps. 'All Styles' = any style.", x: 0, y: 2, width: 4, height: 1}
        {class: "dropdown", name: "styles", label: "Styles (in-line only, regex or exact)", items: style_items, value: settings.styles or last_settings_defaults.styles, x: 0, y: 3}
    }

inline_swap = (subs, sel, delimiter, styles) ->
    esc = delimiter\gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')

    patt1 = '{' .. esc .. '}' .. '([^{]*)' .. '{' .. esc .. '([^}]*)}'
    repl1 = '{' .. delimiter .. '}%2{' .. delimiter .. '%1}'

    patt2 = '{' .. esc .. esc .. '([^}]+)}'
    repl2 = '{' .. delimiter .. '}%1{' .. delimiter .. '}'

    patt3 = '{' .. esc .. '}{' .. esc
    repl3 = '{' .. delimiter .. delimiter

    line_marker = delimiter .. delimiter .. delimiter

    style_regex = nil

    if styles == 'All'
        style_regex = nil
    else
        ok, rx = pcall(-> rex_pcre(styles))

        if ok and rx
            style_regex = rx
        else
            style_regex = nil

    for i in *sel
        line = subs[i]

        if line.class == 'dialogue'
            if line.effect and line.effect == line_marker
                line.comment = not line.comment

            style_ok = false

            if styles == 'All'
                style_ok = true
            elseif style_regex
                style_ok = style_regex:match(line.style)
            else
                style_ok = line.style == styles

            if style_ok
                text = line.text

                text = text\gsub(patt1, repl1)
                text = text\gsub(patt2, repl2)
                text = text\gsub(patt3, repl3)

                line.text = text

            subs[i] = line

full_event_swap = (subs, sel, key) ->
    lines = {}

    for i in *sel
        line = subs[i]

        if (line.class == "dialogue" or line.class == "comment") and line.effect == key
            table.insert lines, {i, line}

    for j = 1, #lines-1, 2
        idx1, l1 = unpack lines[j]
        idx2, l2 = unpack lines[j+1]

        subs[idx1], subs[idx2] = l2, l1

run_weebswap_on_all = (subs, delimiter, styles) ->
    all_sel = {}
    for i = 1, #subs
        if subs[i].class == 'dialogue'
            table.insert all_sel, i
    inline_swap subs, all_sel, delimiter, styles

weebswap_macro = (subs, sel) ->
    config\load!

    preset = config\getSectionHandler {"presets", config.c.currentPreset}, defaultConfig

    settings = {
        delimiter: preset.c.delimiter or defaultConfig.delimiter
        styles: preset.c.styles or defaultConfig.styles
    }

    dialog = build_dialog subs, settings

    pressed, res = aegisub.dialog.display(dialog, {"Swap", "Cancel"})

    return unless pressed == "Swap"

    delimiter, styles = res.delimiter, res.styles

    preset.c.delimiter = delimiter
    preset.c.styles = styles
    preset\write!

    run_weebswap_on_all subs, delimiter, styles

    aegisub.set_undo_point script_name

repeat_last_macro = (subs, sel) ->
    config\load!
    preset = config\getSectionHandler {"presets", config.c.currentPreset}, defaultConfig
    delimiter = preset.c.delimiter or defaultConfig.delimiter
    styles = preset.c.styles or defaultConfig.styles
    run_weebswap_on_all subs, delimiter, styles
    aegisub.set_undo_point script_name

validate_weebswap = (subs, sel) -> #sel > 0

depctrl\registerMacro "WeebSwap/Config", "Configure WeebSwap presets", configSetup, validate_weebswap
depctrl\registerMacro "WeebSwap/Repeat Last", "Repeat last swap", repeat_last_macro, validate_weebswap

for name, preset_data in pairs config.c.presets
    delimiter = preset_data.delimiter or defaultConfig.delimiter
    depctrl\registerMacro "WeebSwap/Presets/#{name} [#{delimiter}]", "Swap with preset: #{name} (#{delimiter})",
        (subs, sel) ->
            preset = config\getSectionHandler {"presets", name}, defaultConfig
            delimiter = preset.c.delimiter or defaultConfig.delimiter
            styles = preset.c.styles or defaultConfig.styles
            run_weebswap_on_all subs, delimiter, styles
            aegisub.set_undo_point "#{script_name} (#{name})"
    validate_weebswap
