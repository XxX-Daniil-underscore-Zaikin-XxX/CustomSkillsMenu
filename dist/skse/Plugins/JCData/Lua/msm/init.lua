-- truncates a custom skills entry and leaves behind only the stuff CSM needs

local msm = {}

-- we receive our collection of every Custom Skill at once
-- and we return a trimmed version with only what CSM needs
function msm.truncateV3(collection)
    local ret = JMap.object()

    for filePath, skillSet in pairs(collection) do
        --extract filename

        local showMenu = skillSet["showMenu"]
        local plugin = ""
        -- Some skills are called by their ID instead of showMenu (bad, bad, bad!)
        if showMenu == nil then
            -- search for the plugin via other global vars
            local globalVar = ""
            if skillSet["debugReload"] ~= nil then
                globalVar = skillSet["debugReload"]
            elseif skillSet["perkPoints"] ~= nil then
                globalVar = skillSet["perkPoints"]
            end
            -- if we don't find it, we skip the skill
            if globalVar == nil then
                goto continue
            end
            plugin = globalVar:match("^(.-)|")
            local skills = skillSet["skills"]
            -- iterate through skills, add each one as separate Skill Menu
            for i=1, #skills do
                local skill = skills[i]
                local skillId = skill["id"]
                local processedSkill = msm.processSkillV3(skillId, plugin, 0)
                -- sanity check
                if processedSkill ~= nil then
                    ret[skillId] = processedSkill
                end
            end
        else
            -- set our ID to the fileName
            local skillId = filePath:match("^(.+)%.%w+")
            -- extract plugin and formid from CSF string
            plugin = showMenu:match("^(.-)|")
            local showMenuId = showMenu:match(".-|(.+)")
            -- format formid
            if showMenuId:find("0x") == nil then
                showMenuId = "0x" .. showMenuId
            end
            -- process entire skill tree into one CSM selection
            local processedSkill = msm.processSkillV3(skillId, plugin, showMenuId)
            -- sanity check
            if processedSkill ~= nil then
                ret[skillId] = processedSkill
            end
        end
        ::continue::
    end

    return ret
end

-- Trim and format CSF json into only everything that CSM needs
function msm.processSkillV3(skillId, plugin, showMenuId)
    --sanity check
    if skillId == nil then
        return nil
    end
    local menuEntry = JMap.object()
    -- process showMenu if it's there
    if showMenuId ~= 0 then
        menuEntry["ShowMenu"] = "__formData|" .. plugin .. "|" .. showMenuId
    end
    -- generate CSM data
    menuEntry["Name"] = skillId
    menuEntry["Description"] = "Skills belonging to " .. skillId
    menuEntry["icon_loc"] = "data/interface/MetaSkillsMenu/" ..
            skillId ..
            " " ..
            string.gsub(plugin, ".esp", ".dds")
    menuEntry["icon_exists"] = 0
    menuEntry["plugin"] = plugin
    -- enable it by default; we disable it in Papyrus
    menuEntry["Disabled"] = 0

    return menuEntry
end

-- from the original CSM
-- don't broke what ain't fix
function msm.truncateV2(collection)
    local ret = JMap.object()
    local function trim(s)
        -- from PiL2 20.4
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
    for x = 1, #collection do
        local file = io.open(collection[x], "r")
        if file == nil then
            goto continue
        end
        local content = file:read "*a"
        file:close()
        local t = JMap.object()
        for k, v in string.gmatch(content, "(%w+) =(.-\n)") do
            t[k] = v
            -- cleanup crap
            t[k] = string.gsub(t[k], "\n", "")
            t[k] = string.gsub(t[k], " \\ ", "")
            t[k] = string.gsub(t[k], "\"", "")
            t[k] = trim(t[k])
        end
        if t["Name"]and t["MSM_DoNotShow"] == nil then
            local r = JMap.object()
            r["filePath"] = collection[x]
            r["Name"] = t["Name"]
            r["Description"] = t["Description"]
            if t["ShowMenuFile"] == nil or t["LevelFile"] == "" then
                -- this will be the default action if on CSFv2 as ShowMenuFile is not needed
                if t["LevelFile"] == nil or t["LevelFile"] == "" then
                    r["plugin"] = t["RatioFile"]
                else
                    r["plugin"] = t["LevelFile"]
                end
                r["ShowMenuForm"] = 0
            else
                r["plugin"] = t["ShowMenuFile"]
                r["ShowMenu"] = "__formData|"..t["ShowMenuFile"].."|"..t["ShowMenuId"]
            end
            r["icon_loc"] = "data/interface/MetaSkillsMenu/" .. r["Name"] .. " " .. string.gsub(r["plugin"], ".esp", ".dds")
            r["icon_exists"] = 0
            r["hidden"] = 0
            r["Disabled"] = 0
            local skillId = collection[x]:gsub(".+%/(.-)%.(.-)%.(.-)%.txt", "%2")
             -- construct formdata record
            ret[skillId] = r
        end
        ::continue::
    end
    return ret
end

-- Replace new Name, Description, and icon_loc with original
function msm.mergeMenuOptions(original, new)
    local ret = JMap.object()

    -- update new settings (i.e. autogenerated ones) with original
    for name, menuSetting in pairs(new) do
        local setting = menuSetting
        if original[name] ~= nil then
            msm.setIfExists(original[name], setting, "Name")
            msm.setIfExists(original[name], setting, "Description")
            msm.setIfExists(original[name], setting, "icon_loc")
        end
        -- update if icon exists
        setting["icon_exists"] = msm.file_exists(setting["icon_loc"])
        ret[name] = setting
    end

    -- add missing old settings to return
    for name, menuSetting in pairs(original) do
        if new[name] == nil then
            ret[name] = menuSetting
            -- update flag also
            ret[name]["icon_exists"] = msm.file_exists(menuSetting["icon_loc"])
        end
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
        if hidden == nil then
            goto continue
        end
        local menu = menus[menuName]
        local hiddenSwitch = hidden["hidden"]
        if hiddenSwitch ~= nil then
            if menu ~= nil then
                menu["hidden"] = hiddenSwitch
            end
        else
            menu["hidden"] = false
        end
        ::continue::
    end
    return menus
end

-- transfer menus to hiddenOptions to preserve original mod's functionality
function msm.transferToHidden(menus, hiddenOptions)
    for menuName, menu in pairs(menus) do
        if hiddenOptions[menuName] == nil then
            local newHidden = false
            if menu["hidden"] ~= nil then
                newHidden = menu["hidden"]
            end
            local newHiddenObj = JMap.object()
            newHiddenObj["hidden"] = newHidden
            hiddenOptions[menuName] = newHiddenObj
        end
    end
    return hiddenOptions
end

-- forced to use this helper because JContainers only allows one argument
function msm.mergeMenuOptionsHelper(collection)
    return msm.mergeMenuOptions(collection["original"], collection["new"])
end

-- forced to use this helper because JContainers only allows one argument
function msm.loadCustomMenu(settings)
    return msm.mergeMenuOptions(settings["original"], msm.truncateV3(settings["new"]))
end

-- sets value from tableFrom to tableTo if key exists in tableFrom
function msm.setIfExists(tableFrom, tableTo, key)
    if tableFrom[key] ~= nil then
        tableTo[key] = tableFrom[key]
    end
end

-- check if file exists
-- from https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
function msm.file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
 end
 

return msm

