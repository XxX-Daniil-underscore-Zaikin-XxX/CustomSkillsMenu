Scriptname metaSkillMenuAPI

string      Property CSM_Database           = ".CustomSkillsMenuv3.MenuData"        auto hidden

string      Property CSM_Path               = "data/interface/MetaSkillsMenu"       auto hidden

string      Property CSM_v2Path             = "data/NetScriptFramework/Plugins"     auto hidden
string      Property CSM_v3Path             = "data/SKSE/Plugins/CustomSkills"      auto hidden

string      Property CSM_HiddenFilename     = "MSMHidden.json"                      auto hidden
string      Property CSM_DataFilename       = "MSMData.json"                        auto hidden

string      Property CSM_HiddenFile                                                 hidden
    string Function Get()
        return CSM_Path + "/" + CSM_HiddenFilename
    EndFunction
    Function Set(string value)
    EndFunction
EndProperty

string      Property CSM_DataFile                                                   hidden
    string Function Get()
        return CSM_Path + "/" + CSM_DataFilename
    EndFunction
    Function Set(string value)
    EndFunction
EndProperty

; For all of below, we will assume the JDB is the source of truth

; gets path to JDB entry for the Hidden prop of the skill
string function getSkillHiddenPath(string skillName)
    return CSM_Database + "." + skillName + ".Hidden"
endFunction

bool function GetCSMHidden(string skillName)
    return JDB.solveInt(getSkillHiddenPath(skillName))
endFunction

function SetCSMHidden(string skillName, bool newHidden)
    JDB.solveIntSetter(getSkillHiddenPath(skillName), newHidden as Int)

    SetCSMHiddenInFile(skillName, newHidden, CSM_DataFile)
    SetCSMHiddenInFile(skillName, newHidden, CSM_HiddenFile)
endFunction

function ToggleCSMHidden(string skillName)
    SetCSMHidden(skillName, !GetCSMHidden(skillName))
endFunction

function SetCSMHiddenInFile(string skillName, bool newHidden, string filePath)
    int file = JValue.readFromFile(filePath)

    JValue.solveIntSetter(file, "." + skillName + ".Hidden", newHidden as Int)

    JValue.writeToFile(file, filePath)
    JValue.release(file)
endFunction