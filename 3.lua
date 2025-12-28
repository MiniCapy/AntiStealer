local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local allowedScripts = {
    [script] = true,
}

for _, desc in ipairs(script:GetDescendants()) do
    if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
        allowedScripts[desc] = true
    end
end

local function addToWhitelist(container)
    local success = pcall(function()
        if typeof(container) == "Instance" then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    allowedScripts[obj] = true
                end
            end
            
            container.DescendantAdded:Connect(function(desc)
                task.wait()
                if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
                    allowedScripts[desc] = true
                end
            end)
        end
    end)
    return success
end

pcall(function() addToWhitelist(player:WaitForChild("PlayerGui", 10)) end)
pcall(function() addToWhitelist(player:WaitForChild("PlayerScripts", 10)) end)
pcall(function() addToWhitelist(player:WaitForChild("Backpack", 10)) end)
pcall(function() addToWhitelist(game:GetService("StarterGui")) end)
pcall(function() addToWhitelist(game:GetService("StarterPack")) end)
pcall(function() addToWhitelist(game:GetService("ReplicatedFirst")) end)

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    pcall(function() addToWhitelist(char) end)
end)

if player.Character then
    pcall(function() addToWhitelist(player.Character) end)
end

local function isAllowed(caller)
    if not caller then return true end
    
    local success, isDescendant = pcall(function()
        return caller:IsDescendantOf(game)
    end)
    
    if not success or not isDescendant then return true end
    
    if allowedScripts[caller] then return true end
    
    local current = caller
    for i = 1, 20 do
        local success2, parent = pcall(function()
            return current.Parent
        end)
        
        if not success2 or not parent then break end
        if allowedScripts[parent] then return true end
        current = parent
    end
    
    return false
end

local suspiciousDomains = {
    "pastebin%.com", "hastebin%.com", "mystbin%.com", "bin%.guide",
    "discord%.com/api/webhooks", "discordapp%.com/api/webhooks",
    "canary%.discord", "ptb%.discord",
    "raw%.githubusercontent%.com", "githubusercontent%.com",
    "gitlab%.com", "bitbucket%.org",
    "textbin%.net", "ghostbin%.co", "controlc%.com",
    "paste%.ee", "dpaste%.com", "paste%.org"
}

local legitimatePatterns = {
    "^https?://[%w%-]+%.roblox%.com",
    "^https?://[%w%-]+%.rbxcdn%.com",
    "^https?://api%.roblox%.com",
    "^https?://games%.roblox%.com",
    "^https?://catalog%.roblox%.com",
    "^https?://users%.roblox%.com",
    "^https?://thumbnails%.roblox%.com",
}

local function isLegitimateUrl(url)
    if type(url) ~= "string" then return false end
    
    for _, pattern in ipairs(legitimatePatterns) do
        if url:match(pattern) then
            return true
        end
    end
    
    return false
end

local function isSuspiciousUrl(url)
    if type(url) ~= "string" then return false end
    
    if isLegitimateUrl(url) then return false end
    
    local lower = url:lower()
    
    for _, pattern in ipairs(suspiciousDomains) do
        if lower:match(pattern) then
            return true
        end
    end
    
    return false
end

local function isSuspiciousPayload(payload)
    if type(payload) ~= "string" then return false end
    
    if #payload < 600 then return false end
    
    local lower = payload:lower()
    local suspicionScore = 0
    
    local patterns = {
        "loadstring%s*%(",
        "require%s*%(%s*%d+%s*%)",
        "getfenv%s*%(",
        "setfenv%s*%(",
        "rawget%s*%(",
        "rawset%s*%(",
        "%.source%s*=",
        "hookmetamethod",
        "hookfunction",
        "newcclosure",
        "getnamecallmethod",
        "getcallingscript"
    }
    
    for _, pattern in ipairs(patterns) do
        if lower:match(pattern) then
            suspicionScore = suspicionScore + 1
        end
    end
    
    local longStrings = {}
    for str in payload:gmatch("[%w_]+") do
        if #str > 400 then
            table.insert(longStrings, str)
            suspicionScore = suspicionScore + 2
        end
    end
    
    if payload:match("[A-Za-z0-9+/=]{100,}") then
        suspicionScore = suspicionScore + 1
    end
    
    return suspicionScore >= 3
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if self == HttpService and (method == "GetAsync" or method == "PostAsync" or method == "RequestAsync") then
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if isAllowed(caller) then
            return oldNamecall(self, ...)
        end

        local url = args[1]
        
        if method == "RequestAsync" and typeof(args[1]) == "table" then
            url = args[1].Url
        end
        
        if typeof(url) == "string" and isLegitimateUrl(url) then
            return oldNamecall(self, ...)
        end
        
        if typeof(url) == "string" and isSuspiciousUrl(url) then
            if method == "RequestAsync" then
                return {Success = false, StatusCode = 403, StatusMessage = "Blocked"}
            end
            return ""
        end

        if method == "PostAsync" then
            local body = args[2]
            if isSuspiciousPayload(body) then
                return ""
            end
        end

        if method == "RequestAsync" and typeof(args[1]) == "table" then
            local req = args[1]
            
            if typeof(req.Body) == "string" and isSuspiciousPayload(req.Body) then
                return {Success = false, StatusCode = 403, StatusMessage = "Blocked"}
            end
        end
    end

    return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(t, k)
    if typeof(t) == "Instance" and (t:IsA("LocalScript") or t:IsA("ModuleScript")) and k == "Source" then
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if not isAllowed(caller) then
            return ""
        end
    end
    return oldIndex(t, k)
end))

local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(t, k, v)
    if typeof(t) == "Instance" and (t:IsA("LocalScript") or t:IsA("ModuleScript")) and k == "Source" then
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if not isAllowed(caller) then
            return
        end
    end
    return oldNewIndex(t, k, v)
end))

if loadstring then
    local oldLoadstring = loadstring
    loadstring = newcclosure(function(source, chunkname)
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if isAllowed(caller) then
            return oldLoadstring(source, chunkname)
        end
        
        error("loadstring is protected", 2)
    end)
end

if getgc then
    local oldGetgc = getgc
    getgc = newcclosure(function(...)
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if isAllowed(caller) then
            return oldGetgc(...)
        end
        
        return {}
    end)
end

if getrenv then
    local oldRequire = getrenv().require
    getrenv().require = newcclosure(function(module)
        local caller = getcallingscript and getcallingscript() or (getfenv and getfenv(2).script)
        
        if isAllowed(caller) then
            return oldRequire(module)
        end
        
        if type(module) == "number" then
            error("Asset require is protected", 2)
        end
        
        return oldRequire(module)
    end)
end
