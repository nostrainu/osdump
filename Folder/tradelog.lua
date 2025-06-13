local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local RefreshActivePetsUI = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("RefreshActivePetsUI")

local req = (syn and syn.request) or http_request or request

-- Helper: Get only Age pets
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

-- Format inventory
local function formatInventory(inv)
	local counts = {}
	for _, name in ipairs(inv) do
		local base = name:match("^(.-) %[[^%]]+%] %[[^%]]+%]$") or name
		counts[base] = (counts[base] or 0) + 1
	end

	local lines = {
		"```",
		string.format("%-15s| %s", "Pet", "Count"),
		string.rep("-", 15) .. "|------"
	}
	for name, count in pairs(counts) do
		table.insert(lines, string.format("%-15s| %d", name, count))
	end
	table.insert(lines, "```")

	return #lines > 3 and table.concat(lines, "\n") or "_None_"
end

-- Compare old vs new inventory
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
	for name, count in pairs(diff) do
		table.insert(lines, string.format("- %s × %d", name, count))
	end

	return #lines > 0 and table.concat(lines, "\n") or "_Nothing new_"
end

-- Send webhook
local function sendWebhook(oldInv, newInv, displayName, userId)
	local embed = {
		{
			title = "🎁 Trade Success!",
			description = "**" .. displayName .. "** has accepted a pet gift!",
			color = 16753920,
			fields = {
				{
					name = "📦 Received Pets",
					value = getNewPets(oldInv, newInv)
				},
				{
					name = "🎒 Full Backpack",
					value = formatInventory(newInv)
				}
			},
			thumbnail = {
				url = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. tostring(userId) .. "&size=420x420&format=Png&isCircular=true"
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer = {
				text = "Gift Tracker"
			}
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
			Headers = {
				["Content-Type"] = "application/json"
			},
			Body = payload
		})
	end
end

-- Listen for gift acceptance
RefreshActivePetsUI.OnClientEvent:Connect(function()
	local raw = getgenv().receiever
	local receiver = typeof(raw) == "Instance" and raw or Players:FindFirstChild(raw or "")
	if receiver then
		local before = getAgeInventory(receiver)
		task.wait(0.5)
		local after = getAgeInventory(receiver)
		sendWebhook(before, after, receiver.DisplayName, receiver.UserId)
	end
end)
