Scriptname metaSkillMenuScript extends Quest  
{Controller script for MetaSkillMenu}

; whether the mod and its requirements are installed
bool b_CustomSkillsExists = false
; whether any Custom Skills are installed
bool b_SkillTreesInstalled = false
; whether the Custom Skills native api is installed
bool b_CustomSkillsPapryusAPIExists = false
; whether any Custom Skills are actually viewable (i.e. not hidden)
bool b_SkillTreesPresent = false

event OnInit()
    startup()
endEvent

function startup()
    if doSafetyCheck()
        load_data()
        register_events()
    endif
endfunction

bool function doSafetyCheck()
    If !jcontainers.isInstalled()
        Writelog("JContainers is not detected!\nMake sure you are using the correct JContainers version for your game version.\n\n(jcontainers.isInstalled() did not return true)", 2)
        b_CustomSkillsExists = false
        b_CustomSkillsPapryusAPIExists = false
        return false
    else
        if CustomSkills.GetAPIVersion()
            b_CustomSkillsPapryusAPIExists = true
            b_CustomSkillsExists = true
        elseif jcontainers.fileExistsAtPath("data/NetScriptFramework/Plugins/CustomSkills.dll")
            b_CustomSkillsPapryusAPIExists = false
            b_CustomSkillsExists = true
        else
            b_CustomSkillsPapryusAPIExists = false
            b_CustomSkillsExists = false
            Writelog("Custom Skill Framework by Meh321 was not detected, make sure the mod is installed correctly.\n(Failed to find CustomSkills.dll) or CustomSkills API", 2)
            return false
        endif
        writelog("b_CustomSkillsExists "+b_CustomSkillsExists)
        writelog("b_SkillTreesInstalled "+b_SkillTreesInstalled)
        writelog("b_CustomSkillsPapryusAPIExists "+b_CustomSkillsPapryusAPIExists)
        return true
    endif
endFunction

function register_events()
    registerformodevent("MetaSkillMenu_Open", "OpenMenu")
    registerformodevent("MetaSkillMenu_Close", "CloseMenu")
    registerformodevent("MetaSkillMenu_Selection", "SelectedMenu")
endfunction

; Attempts to read an object from a given filepath. If it doesn't succeed, return an empty object
int function tryGetObjFromFile(string filePath, string poolName)
    if jcontainers.fileExistsAtPath(filePath)
        return JValue.addToPool(JValue.readFromFile(filePath), poolName)
    Else
        return JValue.addToPool(Jmap.Object(), poolName)
    endif
EndFunction

; run on game load
; could be cleaned up and wrapped into loops, but I'm not sure if the comprehensibility trade-off is worth it
function load_data()
    string csfV2Path = "data/NetScriptFramework/Plugins"
    string csfV3Path = "data/SKSE/Plugins/CustomSkills/"
    b_SkillTreesPresent = false
    b_SkillTreesInstalled = false

    ; get contents of CSF v3 directory if it exists
    ; otherwise, return empty object
    int jCsfFilesV3
    if !JContainers.fileExistsAtPath(csfV3Path)
        jCsfFilesV3 = JValue.addToPool(JArray.object(), "menuInfoPool")
    else
        string[] jCsfFileNamesV3 = JContainers.contentsOfDirectoryAtPath(csfV3Path, ".txt") ; if this errors, we get an empty array
        jCsfFilesV3 = JValue.addToPool(JArray.objectWithStrings(jCsfFileNamesV3), "menuInfoPool")
    endif
    ; process the result, empty or otherwise
    int jConfigsV3 = JValue.addToPool(JValue.evalLuaObj(jCsfFilesV3, "return msm.truncateV3(jobject)"), "menuInfoPool")

    ; get contents of CSF v2 directory if it exists
    ; otherwise, return empty object
    int jCsfFilesV2
    if !JContainers.fileExistsAtPath(csfV2Path)
        jCsfFilesV2 = JValue.addToPool(JArray.object(), "menuInfoPool")
    else
        string[] jCsfFileNamesV2 = JContainers.contentsOfDirectoryAtPath(csfV2Path, ".txt") ; if this errors, we get an empty array
        jCsfFilesV2 = JValue.addToPool(JArray.objectWithStrings(jCsfFileNamesV2), "menuInfoPool")
    endif
    ; process result, empty or otherwise
    int jConfigsV2 = JValue.addToPool(JValue.evalLuaObj(jCsfFilesV2, "return msm.truncateV2(jobject)"), "menuInfoPool")

    ; read saved data
    int hideData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMHidden.json", "menuInfoPool")
    int savedData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMData.json", "menuInfoPool")

    ; First we overwrite the CSF v3 .json data with MSMData.json
    int loadedConfigs = JValue.addToPool(JMap.object(), "menuInfoPool")
    JMap.setObj(loadedConfigs, "original", savedData)
    JMap.setObj(loadedConfigs, "new", jConfigsV3)
    int configsTrimmedV3 = JValue.addToPool(JValue.evalLuaObj(loadedConfigs, "return msm.mergeMenuOptionsHelper(jobject)"), "menuInfoPool")

    ; Then we overwrite the CSF v2 data with our combined data
    JMap.setObj(loadedConfigs, "original", configsTrimmedV3)
    Jmap.setObj(loadedConfigs, "new", jConfigsV2)
    int allConfigsTrimmed = JValue.addToPool(JValue.evalLuaObj(loadedConfigs, "return msm.mergeMenuOptionsHelper(jobject)"), "menuInfoPool")

    ; process hidden data also
    int jConfWithHidden = JValue.addToPool(JMap.object(), "menuInfoPool")
    JMap.setObj(jConfWithHidden, "menus", allConfigsTrimmed)
    JMap.setObj(jConfWithHidden, "hidden", hideData)
    int jHiddenReturn = JValue.addToPool(JValue.evalLuaObj(jConfWithHidden, "return msm.applyHiddenHelper(jobject)"), "menuInfoPool")

    int jCustomMenuPreFormatted = JValue.addToPool(JMap.getObj(jHiddenReturn, "menus"), "menuInfoPool")

    ; start at the beginning
    string skillId = jmap.nextkey(jCustomMenuPreFormatted)
    ; WARNING
    ; We only load skill groups with a `ShowMenu`
    while skillId
        
        string filePoolName = "iterateFilePool"
        ; grab object associated with key
        int fileobj = JValue.addToPool(jmap.getobj(jCustomMenuPreFormatted, skillId), filePoolName)
        string pluginName = jmap.getstr(fileobj, "plugin")
        string showMenu = JMap.getStr(fileobj, "ShowMenu")

        Writelog("Loading skills from file: " + skillId)
        if (showMenu == "")
            WriteLog("Legacy or legacy-style skill. Will call CSF with skill ID (" + skillId + ")")
        else
            WriteLog("Using this to display menu: " + JMap.getStr(fileobj, "ShowMenu"))
        endif
        
        WriteLog("Hidden? " + JMap.getInt(fileobj, "hidden"))
        if (game.IsPluginInstalled(pluginName))
            writelog("Found " + pluginName + ", re-enabling skillset", 0)
            JMap.setInt(fileobj, "Disabled", 0)
            ; if at least one is unhidden, then we can open the menu
            if JMap.getInt(fileobj, "hidden") == 0
                b_SkillTreesPresent = True
            endif
            b_SkillTreesInstalled = true
        else
            string skillName = JMap.getStr(fileobj, "Name")
            writelog("FAILED TO FIND MOD FOR " + skillName + ", MISSING ESP: " + pluginName, 0)
            writelog("Disabling skillset " + skillName, 0)
            JMap.setInt(fileobj, "Disabled", 1)
        endif

        ; go to next skillId
        skillId = jmap.nextkey(jCustomMenuPreFormatted, skillId)
        JValue.cleanPool(filePoolName)
    endwhile

    ; write our data to files
    jvalue.writetofile(JMap.getObj(jHiddenReturn, "hidden"), "data/interface/MetaSkillsMenu/MSMHidden.json")
    jvalue.writetofile(jCustomMenuPreFormatted, "data/interface/MetaSkillsMenu/MSMData.json")

    ; write to DB for faster access
    JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", jCustomMenuPreFormatted, createMissingKeys=true)

    JValue.cleanPool("menuInfoPool")
endfunction

event OpenMenu(string eventName, string strArg, float numArg, Form sender)
    doOpenMenu()
endEvent

function doOpenMenu()
    if b_CustomSkillsExists && b_SkillTreesInstalled && b_SkillTreesPresent
        UI.OpenCustomMenu("MetaSkillsMenu/CustomMetaMenu")
    elseif b_SkillTreesInstalled && !b_SkillTreesPresent
        UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
        Writelog("Skill trees found, but none accessible through this menu.", 1)
    else
        UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
        Writelog("No skill trees found, closing menu.", 1)
    endif
endFunction

event CloseMenu(string eventName, string strArg, float numArg, Form sender)
    doCloseMenu()
endEvent

function doCloseMenu()
    UI.Invoke("TweenMenu", "_root.TweenMenu_mc.ShowMenu")
endFunction

event SelectedMenu(string eventName, string strArg, float numArg, Form sender)
    int MSMData = JValue.addToPool(JDB.solveObj(".CustomSkillsMenuv3.MenuData"), "menuData")
    if (!JValue.isExists(MSMData))
        MSMData = JValue.addToPool(JValue.readFromFile("data/interface/MetaSkillsMenu/MSMData.json"), "menuData")
        JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", MSMData, createMissingKeys=true)
    endif

    ; get chosen skill object from config
    int modObject = JValue.addToPool(JMap.getObj(MSMData, strArg), "menuData")

    string showMenu = JMap.getStr(modObject, "ShowMenu")

    if (showMenu == "")
        CustomSkills.OpenCustomSkillMenu(strArg)
    else
        GlobalVariable showMenuVar = JString.decodeFormStringToForm(showMenu) as GlobalVariable
        showMenuVar.Mod(1.0)
    endif
    
    UI.CloseCustomMenu()
    JValue.cleanPool("menuData")
endEvent

function WriteLog(string printMessage, int error = 0)
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