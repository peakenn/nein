local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local function request(url)
    return game:HttpGet(url)
end

local function pingServer(serverId)
    local pingUrl = "https://games.roblox.com/v1/games/%s/servers/%s"
    local req = request(string.format(pingUrl, 15502339080, serverId))
    local body = HttpService:JSONDecode(req)
    
    if body and body.ping then
        return body.ping
    else
        return math.huge -- Return a large value if ping information is not available
    end
end

local function jumpToServer()
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true"
    
    local function fetchServers(url)
        local req = request(url)
        local body = HttpService:JSONDecode(req)
        
        local servers = {}
        
        if body and body.data then
            for _, v in ipairs(body.data) do
                if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        end
        
        return servers, body.nextPageCursor
    end
    
    local function iterateServers(url, deep)
        local servers = {}
        for i = 1, deep, 1 do
            local fetchedServers, nextPageCursor = fetchServers(url)
            for _, serverId in ipairs(fetchedServers) do
                table.insert(servers, serverId)
            end
            url = string.format(sfUrl .. "&cursor=" .. nextPageCursor, 15502339080, "Desc", 100)
            task.wait(0.1)
        end
        return servers
    end
    
    local deep = math.random(1, 3)
    local url = string.format(sfUrl, 15502339080, "Desc", 100)
    
    local servers = iterateServers(url, deep)
    
    local minPing = math.huge
    local selectedServer = nil
    
    for _, serverId in ipairs(servers) do
        local serverPing = pingServer(serverId)
        if serverPing < minPing then
            minPing = serverPing
            selectedServer = serverId
        end
    end
    
    if selectedServer then
        TeleportService:TeleportToPlaceInstance(15502339080, selectedServer, game:GetService("Players").LocalPlayer)
    else
        print("No suitable servers found.")
    end
end

local function onPlayerRemoving(player)
    local playerCount = #game:GetService("Players"):GetPlayers()
    if playerCount < 22 then
        jumpToServer()
    end
end

Players.PlayerAdded:Connect(function(player)
    for i = 1,#alts do
        if player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
            jumpToServer()
        end
    end
end) 

Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(onPlayerAdded)

while true do
    if math.floor(os.clock() - osclock) >= math.random(900, 1200) then
        jumpToServer()
    end
    task.wait(1)
end
