local hs = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer
local pid, jid = game.PlaceId, game.JobId

local qot = queue_on_teleport or function() end
local ntf = function(t, m)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = t,
			Text = m,
			Duration = 5,
		})
	end)
end

local vsd = {}
local bck = 30
local maxB = 120
local rlC = 0
local maxRl = 3
local minD = 5

local vers = { [1223] = true, [1224] = true, [1226] = true, [1231] = true }
local req = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not req then ntf("server hop", "no http request") return end

local verCache = {}

local function gVer(id)
	if verCache[id] then return verCache[id] end
	local ok, res = pcall(function()
		return req({
			Url = ("https://clientsettings.roblox.com/v2/client-version?placeId=%d&jobId=%s"):format(pid, id),
			Method = "GET"
		})
	end)
	if not ok or not res or not res.Body then return nil end
	local b = hs:JSONDecode(res.Body)
	if not b or not b.version then return nil end
	local v = tonumber(b.version:match("version%-(%d+)"))
	verCache[id] = v
	return v
end

if vers[gVer(jid)] then return end

local function cJoin(s)
	if s.playing >= s.maxPlayers then return false end
	for _, p in pairs(s.players or {}) do
		if vsd[p] then return false end
	end
	return true
end

local function aVst(p)
	for _, pId in pairs(p or {}) do
		vsd[pId] = true
	end
end

local function gSrv(c)
	local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(pid)
	if c then url = url .. "&cursor=" .. c end
	local ok, res = pcall(function()
		return req({
			Url = url,
			Method = "GET",
			Headers = { ["Content-Type"] = "application/json" }
		})
	end)
	if not ok or not res or not res.Body then return nil end
	if res.StatusCode == 429 then return "rate_limited" end
	local ok2, dat = pcall(function() return hs:JSONDecode(res.Body) end)
	if not ok2 or type(dat) ~= "table" then return nil end
	return dat
end

task.spawn(function()
	ntf("server hop", "searching servers...")
	local cur, fnd = nil, false

	while not fnd do
		local dat = gSrv(cur)
		if dat == "rate_limited" then
			rlC = rlC + 1
			ntf("server hop", ("rate limited, backing off %d s (%d/%d)"):format(bck, rlC, maxRl))
			wait(bck)
			if rlC >= maxRl then
				ntf("server hop", "many rate limits, cooldown 90s")
				wait(90)
				rlC = 0
				bck = 30
			else
				bck = math.min(bck * 2, maxB)
			end
		elseif dat and dat.data then
			rlC = 0
			bck = 30
			for _, s in ipairs(dat.data) do
				if s.id ~= jid and cJoin(s) and vers[gVer(s.id)] then
					aVst(s.players)
					ntf("server hop", ("joining server %s (%d/%d)"):format(s.id, s.playing, s.maxPlayers))
					print("teleporting to", s.id)
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
					if not ok3 then
						ntf("server hop", "teleport failed: " .. tostring(err))
					end
					fnd = true
					break
				end
			end
			if not fnd then
				cur = dat.nextPageCursor
				if not cur then
					ntf("server hop", "no servers found, retry in 10s...")
					cur = nil
					wait(10)
				else
					wait(minD)
				end
			end
		else
			ntf("server hop", "failed to fetch servers, retry 10s")
			wait(10)
		end
	end
end)
