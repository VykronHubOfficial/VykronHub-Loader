-- Luau · Diagnostico-Conexao.lua · Roblox client/executor · read-only checks
task.spawn(function()
    local Http=game:GetService("HttpService")
    local player=game:GetService("Players").LocalPlayer
    local env=getgenv()
    local report={version="VYKRON-CONNECTION-DIAG-1",utc=os.date("!%Y-%m-%dT%H:%M:%SZ"),capabilities={},profile={},coreGui={},loader={}}
    local input=game:GetService("UserInputService")
    report.touch=input.TouchEnabled;report.keyboard=input.KeyboardEnabled
    local ok,name=pcall(function()return identifyexecutor()end)
    report.executor=ok and tostring(name):sub(1,60) or "unknown"
    for _,entry in ipairs({{"request",request},{"http_request",http_request},{"syn.request",syn and syn.request},{"http.request",http and http.request},
        {"getconnections",getconnections},{"readfile",readfile},{"writefile",writefile}}) do report.capabilities[entry[1]]=type(entry[2])=="function" end
    local hub=env.__VykronHub
    report.loader.hubPresent=hub~=nil
    report.loader.build=hub and hub.state and hub.state.build
    report.loader.panic=hub and hub.state and hub.state.panic
    report.loader.stopped=hub and hub.state and hub.state.stopped
    local auth=env.__VykronHubLicense
    local valid,result=pcall(function()return auth and auth:isValid()end)
    report.loader.validLicense=valid and result==true
    local loaded,value=pcall(function()return Http:JSONDecode(readfile("VykronHub/"..player.UserId..".json"))end)
    if loaded and type(value)=="table" and value.userId==player.UserId then
        report.profile.reconnect=type(value.ui)=="table" and value.ui.reconnect==true
        report.profile.panic=value.panic==true;report.profile.autoExecute=value.autoExecute==true
    end
    local readCore,nodes=pcall(function()return game:GetService("CoreGui"):GetDescendants()end)
    report.coreGui.readable=readCore
    if readCore then
        report.coreGui.prompts=0;report.coreGui.reconnectLabels=0;report.coreGui.visibleReconnectLabels=0;report.coreGui.propertyReadFailures=0
        for _,node in ipairs(nodes) do
            local inspected=pcall(function()
            local n=node.Name:lower()
            if n:find("prompt") or n:find("disconnect") then report.coreGui.prompts+=1 end
            if node:IsA("TextButton") or node:IsA("TextLabel") then
                local text=node.Text:lower():gsub("[%s%p]","")
                if text=="reconnect" or text=="reconectar" then
                    report.coreGui.reconnectLabels+=1
                    local visible=true;local parent=node
                    while parent do
                        if parent:IsA("GuiObject") and not parent.Visible or parent:IsA("ScreenGui") and not parent.Enabled then visible=false;break end
                        parent=parent.Parent
                    end
                    if visible and node.AbsoluteSize.X>0 and node.AbsoluteSize.Y>0 then report.coreGui.visibleReconnectLabels+=1 end
                end
            end
            end)
            if not inspected then report.coreGui.propertyReadFailures+=1 end
        end
    end
    local got,network=pcall(function()return Http:JSONDecode(readfile("VykronHub/loader-network.json"))end)
    if got and type(network)=="table" and network.version=="LOADER-NETWORK-TEST1" then
        report.network={}
        for _,row in ipairs(network.requests or {}) do
            if #report.network>=20 then break end
            report.network[#report.network+1]={stage=row.stage,result=row.result,transport=row.transport,elapsed=row.elapsed,status=row.status}
        end
    end
    local path="VykronHub/Diagnostics/connection-"..os.date("!%Y%m%d-%H%M%S")..".json"
    local content=Http:JSONEncode(report)
    local saved=pcall(function()
        if type(makefolder)=="function" then pcall(makefolder,"VykronHub");pcall(makefolder,"VykronHub/Diagnostics")end
        writefile(path,content)
    end)
    if saved then print("[VykronHub] Diagnostic saved: "..path)
    elseif type(setclipboard)=="function" and pcall(setclipboard,content)then print("[VykronHub] Diagnostic copied to clipboard.")
    else print("[VykronHub] Diagnostic: "..content) end
end)
