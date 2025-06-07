Scriptname metaSkillMenuAPI


; there's gotta be a better way to do this...
; but beats me thb
string Function GetCSMPath() global
    return "data/interface/MetaSkillsMenu"
EndFunction

string Function GetCSMJDBPath() global
    return ".CustomSkillsMenuv3.MenuData"
EndFunction



string Function GetDataFilename() global
    return "MSMData.json" 
EndFunction

string Function GetHiddenFilename() global
    return "MSMHidden.json"
EndFunction
                


string Function GetHiddenFilePath() global
    return GetCSMPath() + "/" + GetHiddenFilename()
EndFunction

string Function GetDataFilePath() global
    return GetCSMPath() + "/" + GetDataFilename()
EndFunction


; For all of below, we will assume the JDB is the source of truth

; gets path to JDB entry for the Hidden prop of the skill
string function GetDBSkillHiddenPath(string skillName) global
    return GetCSMJDBPath() + getSkillHiddenPath(skillName)
endFunction

string function GetSkillHiddenPath(string skillName) global
    return "." + skillName + ".Hidden"
endFunction

bool function GetHidden(string skillName) global
    return JDB.solveInt(getSkillHiddenPath(skillName))
endFunction

function SetHidden(string skillName, bool newHidden) global
    JDB.solveIntSetter(getSkillHiddenPath(skillName), newHidden as Int)

    SetHiddenInFile(skillName, newHidden, GetHiddenFilePath())
    SetHiddenInFile(skillName, newHidden, GetDataFilePath())
endFunction

function ToggleHidden(string skillName) global
    SetHidden(skillName, !GetHidden(skillName))
endFunction

function SetHiddenInFile(string skillName, bool newHidden, string filePath) global
    int file = JValue.readFromFile(filePath)

    JValue.solveIntSetter(file, getSkillHiddenPath(skillName), newHidden as Int)

    JValue.writeToFile(file, filePath)
    JValue.release(file)
endFunction