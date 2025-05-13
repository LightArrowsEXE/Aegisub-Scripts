export script_name = "TagStripper"
export script_description = "Removes selected override tags from selected events."
export script_author = "lightarrowsexe"
export script_version = "1.0.0"
export script_namespace = "lightarrowsexe.tagstripper"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/LightArrowsEXE/Aegisub-Scripts/main/DependencyControl.json"
}

-- Tags that take a string argument (see https://aegisub.org/docs/latest/ass_tags/)
string_arg_tags = { ["\\fn"]: true, ["\\r"]: true }

extract_tags = (text) ->
    tags = {}

    for override in text\gmatch "%b{}"
        for tag, _ in pairs(string_arg_tags)
            if override\find(tag, 1, true)
                tags[tag] = true
        for tag in override\gmatch "\\[a-zA-Z]+"
            if not tags[tag]
                tags[tag] = true

    for tag in pairs(tags)
        for string_arg_tag, _ in pairs(string_arg_tags)
            if tag\find("^" .. string_arg_tag) and tag != string_arg_tag
                tags[tag] = nil

    [k for k in pairs tags when type(k) == "string" and #k > 0]

remove_tags = (text, tags_to_remove) ->
    return text unless text

    text = text\gsub("%b{}", (override) ->
        new_override = override

        for _, tag in ipairs(tags_to_remove)
            if type(tag) != "string" or #tag == 0
                continue

            if string_arg_tags[tag]
                pattern = tag .. "[^\\}\\\\]*"
                new_override = new_override\gsub(pattern, '')
            else
                pattern = tag .. "%f[^a-zA-Z][^\\}\\\\]*"
                new_override = new_override\gsub(pattern, '')

        if new_override\match "^%{%s*%}$"
            return ''

        return new_override
    )

    text


build_dialog_fields = (unique_tags) ->
    table.sort(unique_tags)

    fields = {}
    max_cols = 3

    num_tags = #unique_tags
    num_rows = math.ceil(num_tags / max_cols)

    for idx, tag in ipairs unique_tags
        col = (idx - 1) % max_cols
        row = math.floor((idx - 1) / max_cols)

        table.insert fields, {
            class: 'checkbox',
            name: tag,
            label: tag,
            value: false,
            x: col,
            y: row
        }

    fields

tagremover_macro = (subs, sel) ->
    all_tags = {}

    for i in *sel
        line = subs[i]
        for tag in *extract_tags(line.text)
            if type(tag) == "string" and #tag > 0
                all_tags[tag] = true

    unique_tags = {}

    for k in pairs(all_tags)
        if type(k) == "string" and #k > 0
            table.insert(unique_tags, k)

    if #unique_tags == 0
        aegisub.dialog.display(
            {
                {class: 'label', label: 'No override tags found in selected events.', x: 0, y: 0, width: 1, height: 1}
            },
            {'OK'}
        )

        return

    fields = build_dialog_fields(unique_tags)
    pressed, res = aegisub.dialog.display(fields, {'Strip', 'Cancel'})

    if pressed != 'Strip'
        return

    tags_to_remove = [tag for tag in *unique_tags when res[tag]]

    if #tags_to_remove == 0
        return

    for i in *sel
        line = subs[i]
        line.text = remove_tags(line.text, tags_to_remove)
        subs[i] = line

    aegisub.set_undo_point(script_name)

depctrl\registerMacro tagremover_macro
