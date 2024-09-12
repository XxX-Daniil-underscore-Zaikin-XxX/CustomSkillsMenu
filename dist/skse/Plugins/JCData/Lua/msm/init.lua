local jc = jrequire 'jc'

local msm = {}

function msm.returnSkillTreeObject(collection)
    local ret = JMap.object()

    local function trim(s)
        -- from PiL2 20.4
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end

    for x = 1, #collection do
        local file = io.open(collection[x], "r")
        local content = file:read "*a"
        file:close()
        local t = JMap.object()
        --for k, v in string.gmatch(content, "(%w+) = (\"?%w+.?%w?\"?)") do
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
            r["test"] = collection[x]
            r["Name"] = t["Name"]
            r["Description"] = t["Description"]
            r["Skydome"] = t["Skydome"]
            if t["ShowMenuFile"] == nil or t["LevelFile"] == "" then
                -- this will be the default action if on new CSF as ShowMenuFile is no longer needed.
                if t["LevelFile"] == nil or t["LevelFile"] == "" then
                    r["ShowMenuFile"] = t["RatioFile"]
                else
                    r["ShowMenuFile"] = t["LevelFile"]
                end
                r["ShowMenuForm"] = 0
                r["CSFSKSE"] = 1
            else
                r["ShowMenuFile"] = t["ShowMenuFile"]
                r["ShowMenuForm"] = "__formData|"..t["ShowMenuFile"].."|"..t["ShowMenuId"]
                r["CSFSKSE"] = 0
            end
            r["icon_loc"] = "data/interface/MetaSkillsMenu/" .. r["Name"] .. " " .. string.gsub(r["ShowMenuFile"], ".esp", ".dds")
            r["icon_exists"] = 0
            r["hidden"] = 0

             -- construct formdata record
            ret[collection[x]] = r
        end
    end
    return ret
end

return msm