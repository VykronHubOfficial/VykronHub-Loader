-- Licensed TEST27 bootstrap; preserves the normal key flow and installs local test continuity.
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
local base="https://raw.githubusercontent.com/VykronHubOfficial/VykronHub-Loader/837005d15e06b41faf5a064f5932ec2cdef475b9/"
local runtime=game:HttpGet(base.."Arise.lua?v=2.0-test27")
assert(runtime:find("VYKRON-QUEST-RESET-MODE-UTILITIES-2.0-TEST27-20261123",1,true),"Runtime de teste ainda nao atualizado; tente novamente.")
local starter=game:HttpGet(base.."Iniciar-teste.lua?v=2.0-test27")
assert(starter:find("TEST27",1,true),"Starter de teste ainda nao atualizado.")
writefile("VykronHub/Tests/Arise-2.0-test27.lua",runtime)
writefile("VykronHub/Tests/Iniciar-teste-2.0-test27.lua",starter)
assert(loadstring(starter))()
print("[VykronHub TEST27] Ative Farm > Auto Quest e selecione Diarias/Semanais ou Todas. Mantenha Auto Execute ligado para continuar apos teleportes.")
