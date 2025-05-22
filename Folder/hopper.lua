local hs = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer
local pid, jid = game.PlaceId, game.JobId

local qot = queue_on_teleport or function() end
local ntf = function(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = m, Duration = 5})
    end)
end

local vers = { [1223] = true, [1224] = true, [1231] = true }
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not req then ntf("server hop", "no http request") return end

local cache, seen = {}, {}
local backoff, maxBackoff = 30, 120
local rateCount, maxRate = 0, 3
local minDelay = 5

local function getVer(id)
    if cache[id] then return cache[id] end
    local ok, res = pcall(function()
        return req({Url = ("https://clientsettings.roblox.com/v2/client-version?placeId=%d&jobId=%s"):format(pid, id), Method = "GET"})
    end)
    if not ok or not res or not res.Body then return nil end
    local body = hs:JSONDecode(res.Body)
    local v = body and tonumber(body.version:match("version%-(%d+)"))
    cache[id] = v
    return v
end

if vers[getVer(jid)] then return end

local function canJoin(s)
    if s.playing >= s.maxPlayers then return false end
    for _, p in pairs(s.players or {}) do
        if seen[p] then return false end
    end
    return true
end

local function markSeen(plist)
    for _, p in pairs(plist or {}) do
        seen[p] = true
    end
end

local function getServers(cursor)
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(pid)
    if cursor then url = url .. "&cursor=" .. cursor end
    local ok, res = pcall(function()
        return req({Url = url, Method = "GET", Headers = {["Content-Type"] = "application/json"}})
    end)
    if not ok or not res or not res.Body then return nil end
    if res.StatusCode == 429 then return "rate_limited" end
    local ok2, data = pcall(function() return hs:JSONDecode(res.Body) end)
    return ok2 and type(data) == "table" and data or nil
end

task.spawn(function()
    ntf("server hop", "searching servers...")
    local cursor, found = nil, false

    while not found do
        local data = getServers(cursor)
        if data == "rate_limited" then
            rateCount += 1
            ntf("server hop", ("rate limited, backing off %d s (%d/%d)"):format(backoff, rateCount, maxRate))
            wait(backoff)
            if rateCount >= maxRate then
                ntf("server hop", "too many rate limits, cooldown 90s")
                wait(90)
                rateCount, backoff = 0, 30
            else
                backoff = math.min(backoff * 2, maxBackoff)
            end
        elseif data and data.data then
            rateCount, backoff = 0, 30
            for _, s in ipairs(data.data) do
                if s.id ~= jid and canJoin(s) and vers[getVer(s.id)] then
                    markSeen(s.players)
                    ntf("server hop", ("joining server %s (%d/%d)"):format(s.id, s.playing, s.maxPlayers))
                    qot([[
                        repeat task.wait() until game:IsLoaded()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "hopped",
                            Text = "joined new server!",
                            Duration = 5,
                        })
                    ]])
                    local ok3, err = pcall(function()
                        ts:TeleportToPlaceInstance(pid, s.id, lp)
                    end)
                    if not ok3 then ntf("server hop", "teleport failed: " .. tostring(err)) end
                    found = true
                    break
                end
            end
            if not found then
                cursor = data.nextPageCursor
                if not cursor then
                    ntf("server hop", "no servers found, retry in 10s...")
                    cursor = nil
                    wait(10)
                else
                    wait(minDelay)
                end
            end
        else
            ntf("server hop", "failed to fetch servers, retry 10s")
            wait(10)
        end
    end
end)
