local placeId = 15502339080

local function request(url)
    return game:HttpGet(url)
end

local function pingServer(serverId)
    local pingUrl = "https://games.roblox.com/v1/games/%s/servers/%s"
    local req = request(string.format(pingUrl, placeId, serverId))
    local body = game:GetService("HttpService"):JSONDecode(req.Body)

    if body and body.ping then
        return body.ping
    else
        return math.huge -- Return a large value if ping information is not available
    end
end

local function getBestServer()
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true"
    local req = request({ Url = string.format(sfUrl, placeId, "Asc", 100) })
    local body = game:GetService("HttpService"):JSONDecode(req.Body)
    local deep = math.random(1, 3)

    if deep > 1 then
        for i = 1, deep, 1 do
            req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, placeId, "Asc", 100) })
            body = game:GetService("HttpService"):JSONDecode(req.Body)
            task.wait(0.1)
        end
    end

    local servers = {}
    if body and body.data then
        for i, v in next, body.data do
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                v.ping = pingServer(v.id)
                table.insert(servers, v)
            end
        end
    end

    table.sort(servers, function(a, b)
        return a.ping < b.ping
    end)

    return servers[1]
end

local function jumpToServer()
    local bestServer = getBestServer()

    if bestServer then
        game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, bestServer.id, game:GetService("Players").LocalPlayer)
    else
        print("No suitable server found.")
    end
end

local function onPlayerRemoving(player)
    local playerCount = #game:GetService("Players"):GetPlayers()
    if playerCount < 22 then
        jumpToServer()
    end
end

local function onPlayerAdded(player)
    local alts = {"Alt1", "Alt2", "Alt3"} -- Replace with your alt account names
    for _, altName in ipairs(alts) do
        if player.Name == altName and altName ~= game.Players.LocalPlayer.Name then
            jumpToServer()
        end
    end
end

Players.PlayerRemoving:Connect(onPlayerRemoving)
Players.PlayerAdded:Connect(onPlayerAdded)

while true do
    if math.floor(os.clock() - osclock) >= math.random(900, 1200) then
        jumpToServer()
    end
    task.wait(1)
end
