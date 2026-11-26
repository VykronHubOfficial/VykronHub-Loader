-- Luau · Diagnostico-Refill-Teams.lua · executor client · observes existing calls only
local env=getgenv()
local h=assert(env.__VykronHub,"Open Vykron Hub before running this diagnostic.")
assert(h.state and h.state.refillTeams,"Refill team controller unavailable.")
if type(env.VykronRefillTeamDiagStop)=="function"then env.VykronRefillTeamDiagStop()end
local Http=game:GetService("HttpService")
local player=game:GetService("Players").LocalPlayer
local storage=game:GetService("ReplicatedStorage")
local started=os.clock();local stopped=false;local hooks={}
local path="VykronHub/Diagnostics/refill-teams-"..os.date("!%Y%m%d-%H%M%S")..".json"
local report={version="VYKRON-REFILL-TEAM-DIAG-1",build=h.state.build,utc=os.date("!%Y-%m-%dT%H:%M:%SZ"),events={}}
local teamNames={}
pcall(function()for _,row in ipairs(h.state.refillTeams.catalog())do teamNames[row.id]=row.name end end)
local function stateSnapshot()
    local q=h.autoQuest;local job=q.journey;local pending=q.refillTeamPending
    local s=h.state
    return {activeEvent=h.events and h.events.active,kamishTakingOver=s.kamishTakingOver==true,
        kamishEnabled=s.kamish and s.kamish.enabled,insideTrial=storage:GetAttribute("InTimeTrial"),world=storage:GetAttribute("World"),
        autoQuest=q.enabled,limitBreaker=q.limitBreakerEnabled,refillEnabled=q.refillTickets,
        phase=job and job.phase,bucket=job and job.bucket,
        farmTeam=job and teamNames[job.farmTeam],returnTeam=job and teamNames[job.returnTeam],
        pendingPhase=pending and pending.phase,pendingTeam=pending and teamNames[pending.id],pendingAttempts=pending and pending.attempts,
        pendingAge=pending and pending.at and math.max(0,workspace:GetServerTimeNow()-pending.at),
        wornTeam=teamNames[tostring(player:GetAttribute("TeamWorn"))] or (player:GetAttribute("TeamWorn")~=nil and "other" or "unavailable"),
        switchTeams=h.dungeon.utilities and h.dungeon.utilities.switchTeams,
        panic=s.panic,rebirthing=s.rebirthing,paused=player.GameplayPaused,stopped=s.stopped,
        status=type(s.refillTeams.status)=="string" and s.refillTeams.status:sub(1,300) or nil}
end
local function add(kind,details)
    pcall(function()
        if stopped then return end
        report.events[#report.events+1]={t=math.floor((os.clock()-started)*100)/100,kind=kind,details=details,state=stateSnapshot()}
        if #report.events>400 then table.remove(report.events,1)end
    end)
end
local function saveReport()
    report.elapsed=math.floor(os.clock()-started)
    return pcall(function()
        if type(makefolder)=="function"then pcall(makefolder,"VykronHub");pcall(makefolder,"VykronHub/Diagnostics")end
        writefile(path,Http:JSONEncode(report))
    end)
end
local function hook(object,key,describe)
    local original=object[key]
    if type(original)~="function"then return end
    local wrapper=function(...)
        local args=table.pack(...)
        local ok,details=pcall(describe,table.unpack(args,1,args.n))
        add(key,ok and details or nil)
        return original(table.unpack(args,1,args.n))
    end
    object[key]=wrapper
    hooks[#hooks+1]={object=object,key=key,original=original,wrapper=wrapper}
end
hook(h.state.refillTeams,"prepare",function()return {intent="Trial team"}end)
hook(h.state.refillTeams,"finish",function()return {intent="return team"}end)
hook(h.state.refillTeams,"equip",function(id,phase)return {team=teamNames[id] or "none/unknown",phase=phase}end)
hook(h.state,"sendTeamSwitchKey",function(key)return {nativeKey=tostring(key):sub(1,20)}end)
add("start");saveReport()
local function stop()
    if stopped then return end
    add("stop");stopped=true
    for _,item in ipairs(hooks)do if item.object[item.key]==item.wrapper then item.object[item.key]=item.original end end
    local saved=saveReport()
    if saved then print("[VykronHub] Team diagnostic: "..path)
    elseif type(setclipboard)=="function"then pcall(setclipboard,Http:JSONEncode(report));print("[VykronHub] Team diagnostic copied to clipboard.")end
    if env.VykronRefillTeamDiagStop==stop then env.VykronRefillTeamDiagStop=nil end
end
env.VykronRefillTeamDiagStop=stop
print("[VykronHub] Observing team changes for 120 seconds. File: "..path)
task.spawn(function()
    local previous
    while not stopped and os.clock()-started<120 do
        local ok,snapshot=pcall(stateSnapshot)
        if ok then
            -- Receipt age is intentionally excluded from change detection.
            local signature=table.clone(snapshot);signature.pendingAge=nil
            local encoded=Http:JSONEncode(signature)
            if encoded~=previous then add("state-changed");previous=encoded end
        end
        saveReport()
        if env.__VykronHub~=h or h.state.stopped then break end
        task.wait(2)
    end
    stop()
end)
