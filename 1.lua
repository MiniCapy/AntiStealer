local HttpService = game:GetService("HttpService")

local oldGet = HttpService.GetAsync
local oldPost = HttpService.PostAsync
local oldRequest = HttpService.RequestAsync

HttpService.GetAsync = function(self, ...)
    error("HTTP requests blocked by ASP")
end

HttpService.PostAsync = function(self, ...)
    error("HTTP requests blocked by ASP")
end

HttpService.RequestAsync = function(self, ...)
    error("HTTP requests blocked by ASP")
end

local mt = getrawmetatable(HttpService)
if mt then
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex
    
    setreadonly(mt, false)
    
    mt.__index = function(t, k)
        if k == "GetAsync" then return HttpService.GetAsync end
        if k == "PostAsync" then return HttpService.PostAsync end
        if k == "RequestAsync" then return HttpService.RequestAsync end
        return oldIndex(t, k)
    end
    
    mt.__newindex = function(t, k, v)
        if k == "GetAsync" or k == "PostAsync" or k == "RequestAsync" then
            error("Attempt to override blocked HTTP function")
        end
        oldNewIndex(t, k, v)
    end
    
    setreadonly(mt, true)
          end
