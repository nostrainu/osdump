-- 🔁 Cleanup previous instance if script re-executed
if getgenv()._giftTrackerCleanup then
	getgenv()._giftTrackerCleanup()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local RefreshActivePetsUI = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("RefreshActivePetsUI")
local req = (syn and syn.request) or http_request or request

-- 🧳 Get only Age pets from backpack
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

-- 📦 Format inventory into a clean bullet list
local function formatInventory(inv)
	local counts = {}
	for _, name in ipairs(inv) do
		local base = name:match("^(.-) %[[^%]]+%] %[[^%]]+%]$") or name
		counts[base] = (counts[base] or 0) + 1
	end

	local lines = {}
	local maxLines = 20
	local shown = 0
	for name, count in pairs(counts) do
		table.insert(lines, string.format("• **%s** × %d", name, count))
		shown += 1
		if shown >= maxLines then
			table.insert(lines, "_...and more_")
			break
		end
	end

	return #lines > 0 and table.concat(lines, "\n") or "_None_"
end

-- 🎁 Compare inventories to find newly added pets
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
		table.insert(lines, string.format("• **%s** × %d", name, count))
	end

	return #lines > 0 and table.concat(lines, "\n") or "_Nothing new_"
end

-- 🌐 Send or edit webhook message
local function sendWebhook(oldInv, newInv, displayName)
	local embed = {
		{
			title = "🎁 Trade Tracker",
			description = string.format("**%s** has accepted a pet gift!", displayName),
			color = 16753920,
			fields = {
				{
					name = "✨ Newly Received Pets",
					value = getNewPets(oldInv, newInv)
				},
				{
					name = "🎒 Backpack Contents",
					value = formatInventory(newInv)
				}
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer = {
				text = "niggametamethod"
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
			-- Edit existing message
			local editUrl = webhookUrl .. "/messages/" .. messageId
			req({
				Url = editUrl,
				Method = "PATCH",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload
			})
		else
			-- Send new message
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
				else
					warn("⚠️ Webhook sent, but response not parseable:")
					warn(response.Body)
				end
			end
		end
	end
end

-- 👂 Listen for gift acceptance with debounce
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

-- 🧹 Setup cleanup for next execution
getgenv()._giftTrackerCleanup = function()
	if connection then
		connection:Disconnect()
	end
	getgenv()._giftTrackerCleanup = nil
end

print("✅ Trade Tracker loaded. Previous instance cleaned.")
