MY = MY or {}
-----------------------------------------------
-- 本地函数和变量
-----------------------------------------------
local _MY = {
    szTitle = "茗伊插件",
    dwVersion = 0x0020000,
    szBuildDate = "20140227",
    szIniFile  = "Interface/MY/MY.ini",
}
-----------------------------------------------
-- 插件初始化
-----------------------------------------------

-----------------------------------------------
-- 通用函数
-----------------------------------------------
-- (number) MY.FrameToSecondLeft(nEndFrame)     -- 获取nEndFrame剩余秒数
MY.FrameToSecondLeft = function(nEndFrame)
	local nLeftFrame = nEndFrame - GetLogicFrameCount()
	return nLeftFrame / 16
end
