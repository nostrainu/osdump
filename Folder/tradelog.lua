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

-- Send or edit webhook
local function sendWebhook(oldInv, newInv, displayName)
	local embed = {
		{
			title = "🎁 Trade Tracker",
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
			-- PATCH edit existing message
			local editUrl = webhookUrl .. "/messages/" .. messageId
			req({
				Url = editUrl,
				Method = "PATCH",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = payload
			})
		else
			-- POST new message
			local response = req({
				Url = webhookUrl,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = payload
			})

			-- Save message ID for future edits
			local body = response.Body
			if body then
				local decoded = HttpService:JSONDecode(body)
				getgenv().last_message_id = decoded.id
			end
		end
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
		sendWebhook(before, after, receiver.DisplayName)
	end
end)
