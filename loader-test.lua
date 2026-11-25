-- Licensed TEST67 bootstrap; preserves the normal key flow and installs local test continuity.
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
local base="https://raw.githubusercontent.com/VykronHubOfficial/VykronHub-Loader/8c6a6ac3d6feb6bc90ae21e7236055ed1c07f369/"
local runtime=game:HttpGet(base.."Arise.lua?v=2.0-test67")
assert(runtime:find("VYKRON-RIFT-STRATEGIES-2.0-TEST67-20261125",1,true),"Runtime de teste ainda nao atualizado; tente novamente.")
local starter=game:HttpGet(base.."Iniciar-teste.lua?v=2.0-test67")
assert(starter:find("TEST67",1,true),"Starter de teste ainda nao atualizado.")
writefile("VykronHub/Tests/Arise-2.0-test67.lua",runtime)
writefile("VykronHub/Tests/Iniciar-teste-2.0-test67.lua",starter)
assert(loadstring(starter))()
print("[VykronHub TEST67] Auto Rift: ilha fixa, rota e checkpoints configuraveis. Mantenha Auto Execute ligado para continuar o teste apos teleportes.")
