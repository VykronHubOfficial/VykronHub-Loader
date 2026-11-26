-- Licensed TEST73 bootstrap; preserves the normal key flow and installs local test continuity.
local env=getgenv()
local function licensed()
    local ok,result=pcall(function() return env.__VykronHubLicense and env.__VykronHubLicense:isValid() end)
    return ok and result==true
end
if not licensed() then
    assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/VykronHubOfficial/VykronHub-Loader/main/loader.lua")))()
end
local deadline=os.clock()+180
repeat task.wait(0.25) until licensed() and env.__VykronHub and env.__VykronHub.state and env.__VykronHub.state.newHub or os.clock()>=deadline
assert(licensed(),"Ative sua key no loader normal para abrir o teste.")
assert(type(writefile)=="function" and type(readfile)=="function" and type(makefolder)=="function","O executor precisa suportar arquivos para continuar o teste apos teleportes.")
for _,path in ipairs({"VykronHub","VykronHub/Tests"}) do pcall(makefolder,path) end
local base="https://raw.githubusercontent.com/VykronHubOfficial/VykronHub-Loader/8f3417fe3ca3584d51d6991689b9301d9968b0f4/"
local runtime=game:HttpGet(base.."Arise.lua?v=2.0-test68")
assert(runtime:find("VYKRON-TRIAL-RESPONSIVE-2.0-TEST73-20261126",1,true),"Runtime de teste ainda nao atualizado; tente novamente.")
local starter=game:HttpGet(base.."Iniciar-teste.lua?v=2.0-test68")
assert(starter:find("TEST73",1,true),"Starter de teste ainda nao atualizado.")
writefile("VykronHub/Tests/Arise-2.0-test68.lua",runtime)
writefile("VykronHub/Tests/Iniciar-teste-2.0-test68.lua",starter)
assert(loadstring(starter))()
print("[VykronHub TEST73] Trial: resposta de alvos e votos sem pausas perdidas. Mantenha Auto Execute ligado para continuar o teste apos teleportes.")
