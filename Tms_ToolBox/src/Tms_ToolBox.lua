-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
Tms_ToolBox = {
    dwVersion = 0x0030000,
    szBuildDate = "20140209",
}
-----------------------------------------------
-- ……
-----------------------------------------------
-- RegisterCustomData("_WYAutoData.")
local _WYAutoCache = {
    loaded = false,
}
----------------------------------------------------
-- 数据初始化
Tms_ToolBox.Loaded = function()
    OutputMessage("MSG_SYS", "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。\n")
end
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) Tms_ToolBox.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
Tms_ToolBox.GetVersion = function()
	local v = _WYAuto.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- (void) Tms_ToolBox.MenuTip(string str)	-- MenuTip
Tms_ToolBox.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})
end

--(void) Tms_ToolBox.print(optional nChannel, szText)     -- 输出消息
Tms_ToolBox.print = function(nChannel,szText)
	local me = GetClientPlayer()
	if type(nChannel) == "string" then
		szText = nChannel
		nChannel = _WYAutoData.cEchoChanel or PLAYER_TALK_CHANNEL.LOCAL_SYS
	end
	local tSay = {{ type = "text", text = szText }}
	if nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
    end
	if nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
		OutputMessage("MSG_SYS", szText)
	elseif _WYAutoData.bEchoMsg then
		me.Talk(nChannel,"",tSay)
	end
end
--(void) Tms_ToolBox.println(optional nChannel,szText)     -- 换行输出消息
Tms_ToolBox.println = function(nChannel,szText)
	if type(nChannel) == "string" then
        Tms_ToolBox.print(nChannel .. "\n")
    else
        Tms_ToolBox.print(nChannel, szText .. "\n")
	end
end

Tms_ToolBox.RegisterPanel = function( szName, szTitle, fn, szIconTex, dwIconFrame, rgbTitleColor )
    local frame = Station.Lookup("Normal/Tms_ToolBox")
    
    local fx = Wnd.OpenWindow("interface\\Tms_ToolBox\\ui\\TabBox.ini", "aTabBox")
    if fx then    
        local item = fx:Lookup("TabBox")
        Output(item)
        if item then
            item:ChangeRelation(Station.Lookup("Normal/Tms_ToolBox"):Lookup("WndWindow_Total"):Lookup("WndWindow_Tabs"), true, true)
            item:SetName(szName)
            item:SetRelPos(0,100)
            item:Lookup("","Text_TabBox_Title"):SetText(szTitle)
            item:Lookup("","Text_TabBox_Title"):SetFontScheme(18)
        end
    end
    Wnd.CloseWindow(fx)
end
---------------------------------------------------
-- 创建菜单
function Tms_ToolBox.GetMenuList()
	return {  -- 主菜单
        szOption = "茗伊工具箱",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",fnAction = function() 	Station.Lookup("Normal/Tms_ToolBox"):Show() end,
    }
end

---------------------------------------------------
-- 事件注册
OutputMessage("MSG_SYS","[茗伊插件]工具箱加载中……")
TraceButton_AppendAddonMenu( {{ szOption = "茗伊工具箱",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",fnAction = function() 	Station.Lookup("Normal/Tms_ToolBox"):ToggleVisible() end, }} )
Player_AppendAddonMenu( {{ szOption = "茗伊工具箱",szIcon = "ui/Image/UICommon/Talk_Face.UITex";nFrame=119;szLayer = "ICON_LEFT",fnAction = function() 	Station.Lookup("Normal/Tms_ToolBox"):ToggleVisible() end, }} )
---------------------------------------------------
--这一条语句最好放在lua文件的末尾，也就是你定义的函数的后面
Wnd.OpenWindow("Interface\\Tms_ToolBox\\ui\\Tms_ToolBox.ini","Tms_ToolBox")
--第一个参数是窗体文件路径，第二个参数是窗体名，也就是WYAuto.ini的第一行那个名字。
---------------------------------------------------
RegisterEvent("CALL_LUA_ERROR", function() OutputMessage("MSG_SYS", arg0) end)
Tms_ToolBox.RegisterPanel( "szName", "szTitle", "szIconTex", "dwIconFrame", "fn" )