-- truncates a custom skills entry and leaves behind only the stuff CSM needs

local jc = jrequire 'jc'

local msm = {}

-- we receive our collection of every Custom Skill at once
-- and we return a trimmed version with only what CSM needs
function msm.truncate(collection)
    local ret = JMap.object()

    for filePath, skillSet in pairs(collection) do
        local fileName = filePath:match("^(.+)%.%w+")
        local processedSkill = msm.processSkill(fileName, skillSet)
        if processedSkill ~= nil then
            ret[fileName] = processedSkill
        else
            local fuck = JMap.object()
            fuck["Name"] = "go fuck yourself"
            ret[fileName] = fuck
        end
        
    end

    return ret
end

-- we receive our collection of every Custom Skill at once
-- and we return a trimmed version with only what CSM needs
function msm.shit(collection)
    local ret = JMap.object()

    for filePath, skillSet in pairs(collection) do
        local fileName = filePath:match("^(.+)%.%w+")
        ret[fileName] = skillSet
    end

    return ret
end

function msm.processSkill(fileName, skillSet)
    local showMenu = skillSet["showMenu"]
    if fileName == nil or showMenu == nil or showMenu == "" then
        return nil
    end
    local menuEntry = JMap.object()

    local plugin = showMenu:match("^[%w_%-%.]+")

    local isHexFormat = showMenu:find("%|0x")
    if isHexFormat == nil then
        showMenu = showMenu:gsub("%|(%w+)", "%|0x%1")
    end

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

-- --This function finds the filename when given a complete path 
-- --From https://help.interfaceware.com/v6/extract-a-filename-from-a-file-path
-- function msm.getFilename(path)
--     local start, finish = path:find('[%w%s!-={-|]+[_%.].+')
--     return path:sub(start,#path)
-- end

function msm.piss(collection)
    local ret = ""
    for filePath, skillSet in pairs(collection) do
        local thing = skillSet["showMenu"]
        
        if thing ~= nil then
            ret = ret .. " ORG: " .. thing
            local otherThing = thing:match("^[%w_%-%.]+")--string.sub(thing, string.find(thing, "^[]"))string.gsub(thing, "|*", "")
            if otherThing ~= nil then
                ret = ret .. " NEW: " .. otherThing
            end
        end
    end

    return ret
end

-- so we can use the original to customise some values
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

function msm.loadCustomMenu(originalSettings, customSkills)
    return msm.mergeMenuOptions(originalSettings, msm.truncate(customSkills))
end

function msm.gamerMove(gamerArray)
    return msm.loadCustomMenu(gamerArray["original"], gamerArray["new"])
end

-- sets value from tableFrom to tableTo if key exists in tableFrom
function msm.setIfExists(tableFrom, tableTo, key)
    if tableFrom[key] ~= nil then
        tableTo[key] = tableFrom[key]
    end
end

return msm