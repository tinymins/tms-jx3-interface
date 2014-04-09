-----------------------------------------------
-- 本地函数和变量 借鉴大量海鳗源码 @haimanchajian.com
-----------------------------------------------
MY = {
    dwVersion = 0x0030000,
    szBuildDate = "20140209",
    szName = "茗伊插件集",
}
-----------------------------------------------
-- ……
-----------------------------------------------
-- RegisterCustomData("_WYAutoData.")
local _WYAutoCache = {
    loaded = false,
}
-----------------------------------------------
-- 私有函数
-----------------------------------------------
local _MY = {
    tRequest = {},
    tTabs = {},
}
-- get channel header
_MY.tTalkChannelHeader = {
	[PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
	[PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
	[PLAYER_TALK_CHANNEL.RAID] = "/t ",
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
	[PLAYER_TALK_CHANNEL.TONG] = "/g ",
	[PLAYER_TALK_CHANNEL.SENCE] = "/y ",
	[PLAYER_TALK_CHANNEL.FORCE] = "/f ",
	[PLAYER_TALK_CHANNEL.CAMP] = "/c ",
	[PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
-- parse faceicon in talking message
_MY.ParseFaceIcon = function(t)
	if not _MY.tFaceIcon then
		_MY.tFaceIcon = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			_MY.tFaceIcon[tLine.szCommand] = true
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "faceicon" then
				v.type = "text"
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szFace = nil
				local nPos = StringFindW(v.text, "#", nOff)
				if not nPos then
					nPos = nLen
				else
					for i = nPos + 6, nPos + 2, -2 do
						if i <= nLen then
							local szTest = string.sub(v.text, nPos, i)
							if _MY.tFaceIcon[szTest] then
								szFace = szTest
								nPos = nPos - 1
								break
							end
						end
					end
				end
				if nPos >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos) })
					nOff = nPos + 1
				end
				if szFace then
					table.insert(t2, { type = "text", text = szFace })
					nOff = nOff + string.len(szFace)
				end
			end
		end
	end
	return t2
end
----------------------------------------------------
-- 数据初始化
MY.Loaded = function()
    OutputMessage("MSG_SYS", "[手残辅助]数据加载成功，欢迎使用挽月堂手残辅助。\n")
end
-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (string, number) MY.GetVersion()		-- HM的 获取字符串版本号 修改方便拿过来了
MY.GetVersion = function()
	local v = _WYAuto.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
-- (void) MY.MenuTip(string str)	-- MenuTip
MY.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})
end

--[[ (void) MY.RemoteRequest(string szUrl, func fnAction)		-- 发起远程 HTTP 请求
-- szUrl		-- 请求的完整 URL（包含 http:// 或 https://）
-- fnAction 	-- 请求完成后的回调函数，回调原型：function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnAction)
	local page = Station.Lookup("Normal/MY/Page_1")
	if page then
		_MY.tRequest[szUrl] = fnAction
		page:Navigate(szUrl)
	end
end
--[[ (KObject) MY.GetTarget()														-- 取得当前目标操作对象
-- (KObject) MY.GetTarget([number dwType, ]number dwID)	-- 根据 dwType 类型和 dwID 取得操作对象]]
MY.GetTarget = function(dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end
--[[ 根据 dwType 类型和 dwID 设置目标
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- dwType	-- *可选* 目标类型
-- dwID		-- 目标 ID]]
MY.SetTarget = function(dwType, dwID)
	if not dwType or dwType <= 0 then
		dwType, dwID = TARGET.NO_TARGET, 0
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	SetTarget(dwType, dwID)
end
--[[ 判断某个频道能否发言
-- (bool) MY.CanTalk(number nChannel)]]
MY.CanTalk = function(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end
--[[ 切换聊天频道
-- (void) MY.SwitchChat(number nChannel)]]
MY.SwitchChat = function(nChannel)
	local szHeader = _MY.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		SwitchChatChannel("/w " .. nChannel .. " ")
	end
end
--[[ 发布聊天内容
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEmotion])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEmotion])
-- szTarget			-- 密聊的目标角色名
-- szText				-- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
-- nChannel			-- *可选* 聊天频道，PLAYER_TALK_CHANNLE.*，默认为近聊
-- bNoEmotion	-- *可选* 不解析聊天内容中的表情图片，默认为 false
-- bSaveDeny	-- *可选* 在聊天输入栏保留不可发言的频道内容，默认为 false
-- 特别注意：nChannel, szText 两者的参数顺序可以调换，战场/团队聊天频道智能切换]]
MY.Talk = function(nChannel, szText, bNoEmotion, bSaveDeny)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		local tar = MY.GetTarget(me.GetTarget())
		szText = string.gsub(szText, "%$zj", me.szName)
		if tar then
			szText = string.gsub(szText, "%$mb", tar.szName)
		end
		tSay = {{ type = "text", text = szText .. "\n"}}
	end
	if not bNoEmotion then
		tSay = _MY.ParseFaceIcon(tSay)
	end
	me.Talk(nChannel, szTarget, tSay)
	if bSaveDeny and not MY.CanTalk(nChannel) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
		-- change to this channel
		MY.SwitchChat(nChannel)
	end
end

--[[ 重绘Tab窗口 ]]
MY.RedrawTabPanel = function()
    local nTop = 0
    local frame = Station.Lookup("Normal/MY/Window_Tabs"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    for szName, tTab in pairs(_MY.tTabs) do 
        
        local fx = Wnd.OpenWindow("interface\\MY\\ui\\TabBox.ini", "aTabBox")
        if fx then    
            local item = fx:Lookup("TabBox")
            Output(item)
            if item then
                item:ChangeRelation(Station.Lookup("Normal/MY/Window_Tabs"), true, true)
                item:SetName("TabBox_" .. szName)
                item:SetRelPos(0,nTop)
                item:Lookup("","Text_TabBox_Title"):SetText(szTitle)
                item:Lookup("","Text_TabBox_Title"):SetFontScheme(18)
                local w,h = item:GetSize()
                nTop = nTop + h
            end
        end
        Wnd.CloseWindow(fx)
    end
end
MY.RegisterPanel = function( szName, szTitle, fn, szIconTex, dwIconFrame, rgbTitleColor )
    _MY.tTabs[szName] = { szTitle = szTitle, fn = fn, szIconTex = szIconTex, dwIconFrame = dwIconFrame, rgbTitleColor = unpack(rgbTitleColor) }
end
-----------------------------------------------------------------------------
-- UI Event Listener
-----------------------------------------------------------------------------
-- web page title changed
MY.OnTitleChanged = function()
	local szUrl, szTitle = this:GetLocationURL(), this:GetLocationName()
	if szUrl ~= szTitle and _MY.tRequest[szUrl] then
		local fnAction = _MY.tRequest[szUrl]
		fnAction(szTitle, this:GetDocument())
		_MY.tRequest[szUrl] = nil
	end
end
-- mouse hover
MY.OnItemMouseEnter = function()
    local szName = this:GetName()
    Output('OnItemMouseEnter '..szName)
end
MY.OnMouseEnter = function()
    local szName = this:GetName()
    if string.sub(szName, 0, 7) == "TabBox_" then
        this:Lookup("","Image_TabBox_Background"):Hide()
        this:Lookup("","Image_TabBox_Background_Hover"):Show()
    end
    Output('OnMouseEnter '..szName)
end
MY.OnMouseLeave = function()
    local szName = this:GetName()
    if string.sub(szName, 0, 7) == "TabBox_" then
        this:Lookup("","Image_TabBox_Background"):Show()
        this:Lookup("","Image_TabBox_Background_Hover"):Hide()
    end
    Output('OnMouseLeave '..szName)
end
MY.OnLButtonClick = function()
    local szName = this:GetName()
    Output('OnLButtonClick '..szName)
end
MY.OnItemLButtonClick = function()
    local szName = this:GetName()
    Output('OnItemLButtonClick '..szName)
end
---------------------------------------------------
--打开窗体
Wnd.OpenWindow("Interface\\MY\\ui\\MY.ini","MY")
---------------------------------------------------
-- 创建菜单
local tMenu = {{ szOption = "茗伊插件",fnAction = function() Station.Lookup("Normal/MY"):ToggleVisible() end, bCheck = true, bChecked = Station.Lookup("Normal/MY"):IsVisible() }}
TraceButton_AppendAddonMenu( tMenu )
Player_AppendAddonMenu( tMenu )
---------------------------------------------------
-- 事件注册
RegisterEvent("CALL_LUA_ERROR", function() OutputMessage("MSG_SYS", arg0) end)
MY.RegisterPanel( "szName", "szTitle", "fn", "szIconTex", "dwIconFrame", {0,0,0} )
MY.RegisterPanel( "szName1", "szTitle", "fn", "szIconTex", "dwIconFrame", {0,0,0} )
MY.RegisterPanel( "szName2", "szTitle", "fn", "szIconTex", "dwIconFrame", {0,0,0} )
MY.RedrawTabPanel()
OutputMessage("MSG_SYS","[茗伊插件]工具箱加载中……")

