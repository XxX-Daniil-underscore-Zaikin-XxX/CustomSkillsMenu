Scriptname metaSkillMenuScript extends Quest  
{Controller script for MetaSkillMenu}
; Sorry for anybody reading this, this is not a good mod to learn from. I'm doing some weird shit here.

bool b_CustomSkillsExists = false
bool b_SkillTreesInstalled = false
bool b_CustomSkillsPapryusAPIExists = false

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

; sets value of object at key if key doesn't exist
function setValueIfNoKey(int jObj, string searchKey, string value)
    if (!JMap.hasKey(jObj, key=searchKey))
        JMap.setStr(jObj, searchKey, value)
    endif
endfunction

int function tryGetObjFromFile(string filePath, string poolName)
    if jcontainers.fileExistsAtPath(filePath)
        return JValue.addToPool(JValue.readFromFile(filePath), poolName)
    Else
        return JValue.addToPool(Jmap.Object(), poolName)
    endif
EndFunction

function load_data()
    string poolName = "menuInfoPool"
    ; turn files to array of strings
    int CSFFiles = JValue.addToPool(JValue.readFromDirectory("data/SKSE/Plugins/CustomSkills/", ".json"), poolName)
    jvalue.writetofile(CSFFiles, "data/interface/MetaSkillsMenu/rawData.json")

    ; read saved data
    int hideData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMHidden.json", poolName)
    int savedData = tryGetObjFromFile("data/interface/MetaSkillsMenu/MSMData.json", poolName)

    ; pre-format our data
    int loadedConfigs = JMap.object()
    JMap.setObj(savedData, "original", loadedConfigs)
    JMap.setObj(CSFFiles, "new", loadedConfigs)
    int test = Jmap.getobj(CSFFiles, "VicHand2Hand.json")
    WriteLog(Jmap.getstr(test, "showMenu"))
    WriteLog(JValue.evalLuaStr(CSFFiles, "return msm.piss(jobject)"))
    ;int allConfigsFormatted = JValue.addToPool(JValue.evalLuaObj(loadedConfigs, "return msm.gamerMove(jobject)"), poolName)
    int allConfigsFormatted = JValue.addToPool(JValue.evalLuaObj(CSFFiles, "return msm.truncate(jobject)"), poolName)

    int testSkill = JValue.evalLuaObj(test, "return msm.processSkill('VicHand2Hand', jobject)")
    WriteLog("holy shit this is so frustrating: " + JMap.getStr(testSkill, "Name"))
    WriteLog("holy shit this is so frustrating: " + JMap.getStr(testSkill, "Description"))
    WriteLog("holy shit this is so frustrating: " + JMap.getStr(testSkill, "ShowMenu"))
    WriteLog("holy shit this is so frustrating: " + JMap.getStr(testSkill, "icon_loc"))
    WriteLog("holy shit this is so frustrating: " + JMap.getStr(testSkill, "plugin"))

    int testObj = JValue.evalLuaObj(CSFFiles, "return msm.shit(jobject)")

    string filekeytest = jmap.nextkey(testObj)

    while filekeytest
        WriteLog("fuck me bloody this fucking sucks:" + filekeytest)
    ; WriteLog("fuck me bloody this fucking sucks:" + JValue.solveStr(testobj, "myskill.Name"))
    ; WriteLog("fuck me bloody this fucking sucks:" + JValue.solveStr(testobj, "myskill.Description"))
        WriteLog("fuck me bloody this fucking sucks:" + JValue.solveStr(testobj, ".myskill.showMenu"))
        WriteLog("fuck me bloody this fucking sucks:" + JMap.haskey(testObj, filekeytest))
        int fuck = JMap.getobj(testobj, filekeytest)
        WriteLog("fuck me bloody this fucking sucks:" + JMap.getstr(fuck, "showMenu"))
        filekeytest = jmap.nextKey(testObj, filekeytest)
    endwhile

    

    ; start at the beginning
    string filekey = jmap.nextkey(allConfigsFormatted)
    ; WARNING
    ; We only load skill groups with a `ShowMenu`
    while filekey
        string filePoolName = "iterateFilePool"
        ; grab object associated with key
        int fileobj = JValue.addToPool(jmap.getobj(allConfigsFormatted, filekey), filePoolName)
        WriteLog("sanity check: " + JMap.getStr(fileobj, "Name"))
        string pluginName = jmap.getstr(fileobj, "plugin")
        ;; oh my god why did I write this terrible code, it's jibberish
        ; yeah it sure is, did you write it on your phone or something?
        writelog("Loading skills from file: " + filekey)
        WriteLog("Using this .esp: " + pluginName)
        if (game.IsPluginInstalled(pluginName))
            ; copy the object (we'll change it and return it)
            int retobj = JValue.addToPool(jvalue.deepcopy(fileobj), filePoolName)

            ; get icon location, set flag if exists
            string icon_loc = jmap.getstr(fileobj, "icon_loc")
            if JContainers.fileExistsAtPath(icon_loc)
                jmap.setint(retobj, "icon_exists", true as int)
            endif

            ; adds retobj under the key asSkillId to config storage
            jmap.setobj(allConfigsFormatted, filekey, retobj)

            ; check hideData for whether modNameThing is hidden
            string hiddenPath = "." + filekey + ".hidden"
            int valuetype = JValue.solvedValueType(hideData, hiddenPath)
            if valuetype != 2 ; if not int, i.e. if we don't find it
                ; we go into the file and set it as false
                JValue.SolveIntSetter(hideData, hiddenPath, false as int, true)
            endif ; MOD NAME THING HUH, WHAT A FUCKING AMAZING NAME ; haha, I'm keeping it then lol
            ; *now* we read it from the file
            jmap.setInt(retObj, "hidden", JValue.SolveInt(hideData, hiddenPath))
        else
            writelog("FAILED TO FIND MOD, MISSING ESP: " + pluginName, 2)
        endif

        ; go to next filekey
        filekey = jmap.nextkey(CSFFiles, filekey)
        JValue.cleanPool(filePoolName)
    endwhile

    ; check if we even found anything
    if jmap.count(allConfigsFormatted) > 0
        b_SkillTreesInstalled = true
    Else
        b_SkillTreesInstalled = false
    endif

    ; write our data to files
    jvalue.writetofile(hideData, "data/interface/MetaSkillsMenu/MSMHidden.json")
    jvalue.writetofile(allConfigsFormatted, "data/interface/MetaSkillsMenu/MSMData.json")
    JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", allConfigsFormatted, createMissingKeys=true)
    int testFinal = JDB.solveobj(".CustomSkillsMenuv3.MenuData")
    string testkey = JMap.nextkey(testFinal)
    while testkey
        WriteLog("This fucking sucks dude: " + testkey)
        testkey = JMap.nextKey(testFinal, testkey)
    endwhile
    JValue.cleanPool(poolName)

    int testFinal2 = JDB.solveobj(".CustomSkillsMenuv3.MenuData")
    testkey = JMap.nextkey(testFinal2)
    while testkey
        WriteLog("This fucking sucks dude 2: " + testkey)
        testkey = JMap.nextKey(testFinal2, testkey)
    endwhile
endfunction

event OpenMenu(string eventName, string strArg, float numArg, Form sender)
    doOpenMenu()
endEvent

function doOpenMenu()
    if b_CustomSkillsExists && b_SkillTreesInstalled
        UI.OpenCustomMenu("MetaSkillsMenu/CustomMetaMenu")
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

; CSF presents forms as e.g. example.esp|0xD61 - not compabitle with JContainers
Form function getFormFromCsfString(string csfString)
    string[] csfForm = StringUtil.Split(csfString, "|")
    string formFile = csfForm[0]
    int formId = PO3_SKSEFunctions.StringToInt(csfForm[1])

    Form retForm = Game.GetFormFromFile(formId, formFile)

    if (!retForm) 
        WriteLog("Could not find form " + csfForm[1] + " in mod " + formFile, 1)
    endif

    return retForm
EndFunction

event SelectedMenu(string eventName, string strArg, float numArg, Form sender)
    int MSMData = JValue.addToPool(JDB.solveObj(".CustomSkillsMenuv3.MenuData"), "menuData")
    if (MSMData == 0)
        MSMData = JValue.addToPool(JValue.readFromFile("data/interface/MetaSkillsMenu/MSMData.json"), "menuData")
        JDB.solveObjSetter(".CustomSkillsMenuv3.MenuData", MSMData, createMissingKeys=true)
    endif
    ; get chosen skill object from config
    int modObject = JValue.addToPool(JMap.getObj(MSMData, strArg), "menuData")
    WriteLog("Did we find " + strArg + "? " + JValue.isExists(modObject))
    WriteLog("alright, this shit sucks: " + JMap.getStr(modObject, "ShowMenu"))
    WriteLog("I will cry: " + JMap.valueType(modObject, "ShowMenu"))
    GlobalVariable showMenuVar = JString.decodeFormStringToForm(JMap.getStr(modObject, "ShowMenu")) as GlobalVariable
    showMenuVar.Mod(1.0)
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