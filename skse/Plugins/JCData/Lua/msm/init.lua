-- truncates a custom skills entry and leaves behind only the stuff CSM needs

local msm = {}

-- we receive our collection of every Custom Skill at once
-- and we return a trimmed version with only what CSM needs
function msm.truncate(collection)
    local ret = JMap.object()

    for filePath, skillSet in pairs(collection) do
        --extract filename
        local fileName = filePath:match("^(.+)%.%w+")
        local processedSkill = msm.processSkill(fileName, skillSet)

        --sanity check
        if processedSkill ~= nil then
            ret[fileName] = processedSkill
        end
    end

    return ret
end

-- Trim and format CSF json into only everything that CSM needs
function msm.processSkill(fileName, skillSet)
    local showMenu = skillSet["showMenu"]

    --sanity check
    if fileName == nil or showMenu == nil or showMenu == "" then
        return nil
    end
    local menuEntry = JMap.object()

    --extract plugin from form
    local plugin = showMenu:match("^(.-)|")

    -- standardize hex format
    local isHexFormat = showMenu:find("%|0x")
    if isHexFormat == nil then
        showMenu = showMenu:gsub("%|(%w+)", "%|0x%1")
    end

    -- generate CSM data
    menuEntry["Name"] = fileName
    menuEntry["Description"] = "Skills belonging to " .. fileName
    menuEntry["ShowMenu"] = "__formData|" .. showMenu
    menuEntry["icon_loc"] = "data/interface/MetaSkillsMenu/" ..
            fileName ..
            " " ..
            string.gsub(plugin, ".esp", ".dds")
    menuEntry["icon_exists"] = false
    menuEntry["plugin"] = plugin

    return menuEntry
end

-- Replace new Name, Description, and icon_loc with original
function msm.mergeMenuOptions(original, new)
    local ret = JMap.object()

    for name, menuSetting in pairs(new) do
        local setting = menuSetting
        msm.setIfExists(original[name], setting, "Name")
        msm.setIfExists(original[name], setting, "Description")
        msm.setIfExists(original[name], setting, "icon_loc")

        ret[name] = setting
    end

    return ret
end

function msm.applyHiddenHelper(configs)
    return msm.applyHidden(configs["menus"], configs["hidden"])
end

-- searches through hiddenOptions and sets the hidden option in menus accordingly
-- at the same time, adds all menus to hiddenOptions
function msm.applyHidden(menus, hiddenOptions)
    local ret = JMap.object()

    ret["menus"] = msm.setHidden(menus, hiddenOptions)
    ret["hidden"] = msm.transferToHidden(menus, hiddenOptions)

    return ret
end

-- sets the hidden key of each menu item based on the hiddenoption
function msm.setHidden(menus, hiddenOptions)
    for menuName, hidden in pairs(hiddenOptions) do
        local menu = menus[menuName]
        if menu ~= nil then
            menu["hidden"] = hidden
        end
    end

    return menus
end

-- transfer menus to hiddenOptions to preserve original mod's functionality
function msm.transferToHidden(menus, hiddenOptions)
    for menuName, menu in pairs(menus) do
        if hiddenOptions[menuName] == nil then
            local newHidden = 0
            if menu["hidden"] ~= nil then
                newHidden = menu["hidden"]
            end
            hiddenOptions[menuName] = {hidden = newHidden}
        end
    end
    
    return hiddenOptions
end

-- forced to use this helper because JContainers only allows one argument
function msm.loadCustomMenu(settings)
    return msm.mergeMenuOptions(settings["original"], msm.truncate(settings["new"]))
end

-- sets value from tableFrom to tableTo if key exists in tableFrom
function msm.setIfExists(tableFrom, tableTo, key)
    if tableFrom[key] ~= nil then
        tableTo[key] = tableFrom[key]
    end
end

return msm