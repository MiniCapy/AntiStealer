local HttpService=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local player=Players.LocalPlayer

local oldGet=HttpService.GetAsync
local oldPost=HttpService.PostAsync
local oldRequest=HttpService.RequestAsync
local oldEncode=HttpService.JSONEncode
local oldDecode=HttpService.JSONDecode
local oldUrlEncode=HttpService.UrlEncode

HttpService.GetAsync=function(...)error()end
HttpService.PostAsync=function(...)error()end
HttpService.RequestAsync=function(...)error()end
HttpService.JSONEncode=function(...)error()end
HttpService.JSONDecode=function(...)error()end
HttpService.UrlEncode=function(...)error()end

local mt=getrawmetatable(HttpService)
if mt then
    local oldIndex=mt.__index
    local oldNewIndex=mt.__newindex
    setreadonly(mt,false)
    mt.__index=function(t,k)
        if k=="GetAsync" or k=="PostAsync" or k=="RequestAsync" or k=="JSONEncode" or k=="JSONDecode" or k=="UrlEncode" then
            return HttpService[k]
        end
        return oldIndex(t,k)
    end
    mt.__newindex=function(t,k,v)
        if k=="GetAsync" or k=="PostAsync" or k=="RequestAsync" or k=="JSONEncode" or k=="JSONDecode" or k=="UrlEncode" then
            error()
        end
        oldNewIndex(t,k,v)
    end
    setreadonly(mt,true)
end

local function protect(obj)
    if typeof(obj)=="Instance" then
        local mt=getrawmetatable(obj)
        if mt then
            setreadonly(mt,false)
            local oldIndex=mt.__index
            local oldNewIndex=mt.__newindex
            mt.__index=function(t,k)
                if k=="Source" and t:IsA("LocalScript") or t:IsA("ModuleScript") then
                    error()
                end
                return oldIndex(t,k)
            end
            mt.__newindex=function(t,k,v)
                if k=="Source" and t:IsA("LocalScript") or t:IsA("ModuleScript") then
                    error()
                end
                oldNewIndex(t,k,v)
            end
            setreadonly(mt,true)
        end
    end
end

for _,script in ipairs(game:GetDescendants()) do
    if script:IsA("LocalScript") or script:IsA("ModuleScript") then
        protect(script)
    end
end

game.DescendantAdded:Connect(function(desc)
    if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
        protect(desc)
    end
end)

local oldNamecall
oldNamecall=hookmetamethod(game,"__namecall",function(self,...)
    local method=getnamecallmethod()
    if self==HttpService then
        if method=="GetAsync" or method=="PostAsync" or method=="RequestAsync" or method=="JSONEncode" or method=="JSONDecode" or method=="UrlEncode" then
            error()
        end
    end
    if method=="Clone" or method=="FindFirstChild" or method=="WaitForChild" then
        local args={...}
        if typeof(args[1])=="string" and (args[1]:lower():find("http") or args[1]:lower():find("request")) then
            error()
        end
    end
    return oldNamecall(self,...)
end)

local oldIndex=hookmetamethod(game,"__index",function(t,k)
    if t==HttpService then
        if k=="GetAsync" or k=="PostAsync" or k=="RequestAsync" or k=="JSONEncode" or k=="JSONDecode" or k=="UrlEncode" then
            error()
        end
    end
    if typeof(t)=="Instance" and (t:IsA("LocalScript") or t:IsA("ModuleScript")) and k=="Source" then
        error()
    end
    return oldIndex(t,k)
end)

local oldNewIndex=hookmetamethod(game,"__newindex",function(t,k,v)
    if typeof(t)=="Instance" and (t:IsA("LocalScript") or t:IsA("ModuleScript")) and k=="Source" then
        error()
    end
    return oldNewIndex(t,k,v)
end)

spawn(function()
    while true do
        wait(5)
        for _,script in ipairs(player.PlayerScripts:GetDescendants()) do
            if script:IsA("LocalScript") or script:IsA("ModuleScript") then
                pcall(function()
                    if script.Source~="" then
                        script.Source=""
                    end
                end)
            end
        end
    end
end)

loadstring=function()error()end
getfenv=function()return {}end
setfenv=function()end
getgc=function()return {}end
