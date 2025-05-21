--// Short Aliases
local rs, ps, hs = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("HttpService")
local plr, name = ps.LocalPlayer, ps.LocalPlayer.DisplayName
local buyEv = rs:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock")
local req = (syn and syn.request) or http_request or request

--// Config
local wU, uID = _G.webhookUrl or "", _G.userId or ""
local bl, got = {}, {}; for _, v in ipairs(_G.blacklist or {}) do bl[v] = true end

--// Prevent Double Execution
if _G._connectionTable then for _, c in pairs(_G._connectionTable) do pcall(function() c:Disconnect() end) end end
_G._connectionTable, _G._sessionID = {}, tick() .. math.random(1e6)
_G._totalBought = {}

--// Webhook Sender
local function wh(title, fields, color)
	if not req or wU == "" then return end
	local body = {
		embeds = {{
			title = title,
			color = color or 0x00FF00,
			fields = fields,
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		}}
	}
	pcall(function()
		req({
			Url = wU,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = hs:JSONEncode(body)
		})
	end)
end

--// Smart Buyer
local DataService = require(rs.Modules:WaitForChild("DataService"))
local function buy()
	local stocks = DataService:GetData().EventShopStock.Stocks
	local newBuys = {}
	for name, _ in pairs(stocks) do
		if not bl[name] then
			buyEv:FireServer(name)
			table.insert(got, name)
			_G._totalBought[name] = (_G._totalBought[name] or 0) + 1
			table.insert(newBuys, name)
			task.wait(0.05)
		end
	end

	if #newBuys > 0 then
		local list = "• " .. table.concat(newBuys, "\n• ")
		local ping = table.find(newBuys, "Candy Blossom") and uID ~= "" and "<@" .. uID .. ">" or "No ping"
		wh("Stock Purchased", {
			{ name = "Info", value = ping, inline = false },
			{ name = "Stocks", value = list, inline = false },
			{ name = "User", value = name, inline = false }
		}, 0x00FF00)
	end
end

--// BloodMoon & NightEvent Hooks
local function onNight()
	if _G._nightTriggered then return end
	_G._nightTriggered = true
	wh("Night Event Started", {{ name = "From", value = name }}, 0x0000FF)
end

local function onBlood()
	if _G._bloodTriggered then return end
	_G._bloodTriggered = true
	wh("BloodMoon Event Started", {{ name = "From", value = name }}, 0xFF0000)
	buy()
end

--// Setup Listeners (stored to auto-disconnect)
table.insert(_G._connectionTable, workspace:GetAttributeChangedSignal("NightEvent"):Connect(function()
	if workspace:GetAttribute("NightEvent") then onNight() end
end))
table.insert(_G._connectionTable, workspace:GetAttributeChangedSignal("BloodMoonEvent"):Connect(function()
	if workspace:GetAttribute("BloodMoonEvent") then onBlood() end
end))

--// Manual Checks (on startup)
if workspace:GetAttribute("NightEvent") then onNight() end
if workspace:GetAttribute("BloodMoonEvent") then onBlood() end

--// Initial Log
wh("Script Started", {
	{ name = "User", value = name },
	{ name = "Session", value = _G._sessionID }
}, 0xFFFFFF)

--// Finalizer (optional: bind to leave/game close)
game:BindToClose(function()
	local summary = {}
	for k, v in pairs(_G._totalBought) do
		table.insert(summary, k .. ": " .. v)
	end
	if #summary > 0 then
		wh("Session Ended", {
			{ name = "Bought", value = table.concat(summary, "\n") },
			{ name = "User", value = name }
		}, 0xAAAAAA)
	end
end)

print("Script loaded and active.")
