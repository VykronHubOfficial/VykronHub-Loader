-- Local Craft TEST66; waits for the normal licensed loader after each teleport.
local E=getgenv()
local P=game:GetService("Players").LocalPlayer
local Http=game:GetService("HttpService")
local build="VYKRON-RIFT-STRATEGIES-2.0-TEST66-20261125"
local marker="VykronHub/Tests/QuestTest-TEST66-"..P.UserId..".json"
local valid,licensed=pcall(function() return E.__VykronHubLicense:isValid() end)
assert(valid and licensed,"Execute primeiro o loader normal com sua key valida.")
if type(E.VykronCraftTestStop)=="function" then E.VykronCraftTestStop() end
local h=E.__VykronHub
if not h or h.state.build~=build then
    assert(loadstring(readfile("VykronHub/Tests/Arise-2.0-test66.lua")))()
    h=assert(E.__VykronHub)
end
assert(h.state.build==build,"TEST66 nao carregada.")
local stopped=false
local function checkpoint()
    if stopped then return end
    h.state.craftPersistenceStep()
    writefile(marker,Http:JSONEncode({userId=P.UserId,armed=true,expires=os.time()+7200,
        riftSettings=h.dungeon and h.dungeon.rift,selectedMode=h.dungeon and h.dungeon.mode,riftEnabled=h.dungeon and h.dungeon.enabled,activeMode=h.state.craft.activeMode,activeUID=h.state.craft.activeUID,resetQuests=h.autoQuest.resetQuests,resetPending=h.autoQuest.resetPending,resetInterval=h.autoQuest.resetInterval,resetDue=h.autoQuest.resetDue,nativeAFK=h.autoQuest.nativeAFK,questSettings=h.autoQuest}))
end
checkpoint()
local connection=P.OnTeleport:Connect(function(phase)
    if phase==Enum.TeleportState.Started then pcall(checkpoint) end
end)
E.VykronCraftTestStop=function()
    stopped=true;connection:Disconnect()
    pcall(writefile,marker,Http:JSONEncode({userId=P.UserId,armed=false}))
end
local continuation=[====[
task.spawn(function()
    local E=getgenv()
    local P=game:GetService("Players").LocalPlayer
    local Http=game:GetService("HttpService")
    local deadline=os.clock()+60
    local ready=false
    repeat
        local ok,valid=pcall(function() return E.__VykronHubLicense:isValid() end)
        ready=ok and valid and E.__VykronHub and E.__VykronHub.state and E.__VykronHub.state.newHub
        if not ready then task.wait(0.5) end
    until ready or os.clock()>=deadline
    if not ready then return end
    local ok,m=pcall(function() return Http:JSONDecode(readfile("VykronHub/Tests/QuestTest-TEST66-"..P.UserId..".json")) end)
    if not ok or type(m)~="table" or m.userId~=P.UserId or m.armed~=true or type(m.expires)~="number" or m.expires<os.time() then return end
    -- Preserve the test-owned Craft and quest intent across the normal bootstrap. Restore
    -- these fields across its normal bootstrap; retain all other live preferences.
    local path="VykronHub/"..P.UserId..".json"
    local profile=Http:JSONDecode(readfile(path))
    assert(profile.userId==P.UserId and type(profile.craft)=="table","Perfil Craft indisponivel")
    profile.craft.activeMode=(m.activeMode=="rank" or m.activeMode=="reroll" or m.activeMode=="infusion") and m.activeMode or nil
    profile.craft.activeUID=type(m.activeUID)=="string" and #m.activeUID<=150 and m.activeUID or nil
    if type(m.questSettings)=="table" then profile.autoQuest=m.questSettings end
    if m.selectedMode=="rift" and type(m.riftSettings)=="table" then profile.dungeon=profile.dungeon or {};profile.dungeon.mode="rift";profile.dungeon.rift=m.riftSettings;profile.dungeon.enabled=m.riftEnabled==true end
    if type(profile.autoQuest)=="table" then profile.autoQuest.resetQuests=m.resetQuests==true;profile.autoQuest.resetPending=m.resetPending;profile.autoQuest.resetInterval=m.resetInterval;profile.autoQuest.resetDue=m.resetDue;profile.autoQuest.nativeAFK=m.nativeAFK end
    writefile(path,Http:JSONEncode(profile))
    assert(loadstring(readfile("VykronHub/Tests/Iniciar-teste-2.0-test66.lua")))()
end)
]====]
local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if E.__VykronCraftTestQueued~=build and type(queue)=="function" then
    local ok=pcall(queue,continuation)
    if ok then E.__VykronCraftTestQueued=build end
end
print("[VykronHub] TEST66: Auto Rift: ilha fixa, rota e checkpoints configuraveis. Auto Execute mantem o teste apos teleportes.")
