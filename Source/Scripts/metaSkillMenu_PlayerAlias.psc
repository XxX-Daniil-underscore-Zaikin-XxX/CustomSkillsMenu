Scriptname metaSkillMenu_PlayerAlias extends ReferenceAlias
{ReferenceAlias script for MetaSkillMenu}
Quest Property MetaSkillsMenu  Auto

event OnPlayerLoadGame()
    onLoad()
endEvent

function onLoad()
    Utility.WaitMenuMode(1.0)
    (MetaSkillsMenu as metaSkillMenuScript).startup()
endfunction