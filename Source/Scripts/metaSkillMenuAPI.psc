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
    return JDB.solveInt(getDBSkillHiddenPath(skillName))
endFunction

function SetHidden(string skillName, bool newHidden) global
    JDB.solveIntSetter(getDBSkillHiddenPath(skillName), newHidden as Int)

    SetHiddenInFile(skillName, newHidden, GetHiddenFilePath())
    SetHiddenInFile(skillName, newHidden, GetDataFilePath())
endFunction

function ToggleHidden(string skillName) global
    SetHidden(skillName, !GetHidden(skillName))
endFunction

bool function GetHiddenInFile(string skillName, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool ret = JValue.solveInt(file, getSkillHiddenPath(skillName))

    JValue.release(file)
    return ret
endFunction

; sets a skill's Hidden property in the given file (assuming skill's name is top level)
function SetHiddenInFile(string skillName, bool newHidden, string filePath) global
    int file = JValue.readFromFile(filePath)
    bool oldHidden = GetHiddenInFile(skillName, filePath)

    if oldHidden != newHidden
        JValue.solveIntSetter(file, getSkillHiddenPath(skillName), newHidden as Int)
        JValue.writeToFile(file, filePath)

        bool updatedHidden = GetHiddenInFile(skillName, filePath)
        if updatedHidden != newHidden
            WriteLog("Unable to update Hidden in " + filePath + " to " + newHidden, 2)
        endif
    endif

    JValue.release(file)
endFunction

function WriteLog(string printMessage, int error = 0) global
    string a = "Custom Skill Menu: "
    if error >= 1
        Debug.Notification(a + printMessage)
    endif
    if error >= 2
        Debug.MessageBox(a +"\n"+ printMessage)
    endif
    ConsoleUtil.PrintMessage(a + printMessage)
    Debug.Trace(a + printMessage)
endfunction