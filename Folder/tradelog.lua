if getgenv()._giftTrackerCleanup then
	getgenv()._giftTrackerCleanup()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local RefreshActivePetsUI = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("RefreshActivePetsUI")
local req = (syn and syn.request) or http_request or request

local function getAgeInventory(player)
	local backpack = player:FindFirstChild("Backpack")
	local inventory = {}
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:find("Age") then
				table.insert(inventory, tool.Name)
			end
		end
	end
	return inventory
end

local function formatTable(inv)
	local counts = {}
	for _, name in ipairs(inv) do
		local base = name:match("^(.-) %[[^%]]+%] %[[^%]]+%]$") or name
		counts[base] = (counts[base] or 0) + 1
	end

	local sorted = {}
	for name, count in pairs(counts) do
		table.insert(sorted, {name = name, count = count})
	end
	table.sort(sorted, function(a, b) return a.name < b.name end)

	local lines = {}
	table.insert(lines, "Pet" .. string.rep(" ", 24 - 3) .. "Count")
	for _, item in ipairs(sorted) do
		local spacing = 25 - #item.name
		local line = item.name .. string.rep(" ", spacing > 0 and spacing or 1) .. "× " .. item.count
		table.insert(lines, line)
	end

	return "```" .. table.concat(lines, "\n") .. "```"
end

local function getNewPets(oldInv, newInv)
	local diff = {}
	local countOld, countNew = {}, {}

	for _, name in ipairs(oldInv) do
		countOld[name] = (countOld[name] or 0) + 1
	end
	for _, name in ipairs(newInv) do
		countNew[name] = (countNew[name] or 0) + 1
	end

	for name, count in pairs(countNew) do
		local added = count - (countOld[name] or 0)
		if added > 0 then
			diff[name] = added
		end
	end

	local lines = {}
	table.insert(lines, "Pet" .. string.rep(" ", 24 - 3) .. "Count")
	for name, count in pairs(diff) do
		local spacing = 25 - #name
		local line = name .. string.rep(" ", spacing > 0 and spacing or 1) .. "× " .. count
		table.insert(lines, line)
	end

	return #lines > 1 and "```" .. table.concat(lines, "\n") .. "```" or "_Nothing new_"
end

local function sendWebhook(oldInv, newInv, displayName)
	local embed = {
		{
			title = "Trade Tracker",
			description = string.format("%s has accepted a pet gift!", displayName),
			color = 16753920,
			fields = {
				{
					name = "Newly Received Pets",
					value = getNewPets(oldInv, newInv)
				},
				{
					name = "Backpack Contents",
					value = formatTable(newInv)
				}
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer = {
				text = "gift tracker by @Lei"
			}
		}
	}

	local payload = HttpService:JSONEncode({
		username = "Lei",
		embeds = embed
	})

	local webhookUrl = getgenv().webhook_url
	if typeof(req) == "function" and typeof(webhookUrl) == "string" then
		local messageId = getgenv().last_message_id

		if messageId then
			req({
				Url = webhookUrl .. "/messages/" .. messageId,
				Method = "PATCH",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload
			})
		else
			local response = req({
				Url = webhookUrl,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload
			})

			if response and typeof(response.Body) == "string" then
				local success, decoded = pcall(function()
					return HttpService:JSONDecode(response.Body)
				end)
				if success and decoded and decoded.id then
					getgenv().last_message_id = decoded.id
				end
			end
		end
	end
end

local function sendSkiddedLog()
	local raw = getgenv().receiever
	local receiver = typeof(raw) == "Instance" and raw or Players:FindFirstChild(raw or "")
	if not receiver then return end

	local embed = {
		{
			title = "Grant Skidded Method",
			color = 16753920,
			fields = {
				{
					name = "Trading",
					value = string.format("%s ➜ %s", LocalPlayer.DisplayName, receiver.DisplayName)
				}
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer = { text = "gift tracker by @Lei" }
		}
	}

	local payload = HttpService:JSONEncode({
		username = "Lei",
		embeds = embed
	})

	local webhookUrl = getgenv().webhook_url
	if typeof(req) == "function" and typeof(webhookUrl) == "string" then
		req({
			Url = webhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = payload
		})
	end
end
sendSkiddedLog()

local debounceTime = 2
local lastUpdate = 0
local connection

connection = RefreshActivePetsUI.OnClientEvent:Connect(function()
	if tick() - lastUpdate < debounceTime then return end
	lastUpdate = tick()

	local raw = getgenv().receiever
	local receiver = typeof(raw) == "Instance" and raw or Players:FindFirstChild(raw or "")
	if receiver then
		local before = getAgeInventory(receiver)
		task.wait(0.5)
		local after = getAgeInventory(receiver)
		sendWebhook(before, after, receiver.DisplayName)
	end
end)

getgenv()._giftTrackerCleanup = function()
	if connection then
		connection:Disconnect()
	end
	getgenv()._giftTrackerCleanup = nil
end

print("✅ Trade Tracker loaded. Previous instance cleaned.")
