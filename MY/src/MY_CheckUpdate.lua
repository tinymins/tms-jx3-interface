MY.RegisterEvent("LOADING_END", function()
    MY.RemoteRequest("https://raw.githubusercontent.com/tinymins/Jx3Interface/master/list.json",function(szTitle,szContent) Output(szTitle) Output(szContent) end)
end)