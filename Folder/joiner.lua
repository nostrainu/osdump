local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local currentJobId = game.JobId

local webhookUrl = "webhook"

local jobList = {
    "f9d9e3de-1639-4c18-96ea-4458cc43f890",
    "e203bab0-b39f-4f21-bd62-ed717196e8e1",
    "c33422fa-05be-4d06-b0d4-b0373d17b494",
    "d7746ce0-8f95-4f07-832f-e1a08b8932f1",
    "88765f25-ceb6-4523-90fe-bef14c09e1dd",
    "047d81e1-82f3-4e73-aad8-8244bf4c3b50",
    "98e740b6-9291-4415-ad47-2e1131f57236",
    "d7746ce0-8f95-4f07-832f-e1a08b8932f1",
    "49ba7ef5-3612-4e66-845e-f8214d50b6d3",
    "5ce83d04-a97d-431a-b66b-f2b9d844ae37",
    "db2ce762-d0e2-454f-ae17-437bc6ad3851",
    "b3b433a8-f26d-4e89-a6ed-8e683b1ed1ac",
    "106aed57-5c6f-4607-aceb-324116765315",
    "9237aaa4-7b07-4fe8-9cfe-8bf1d2e2d4ee",
    "9e5321a0-c2a2-4e47-98b0-04bc2600fba6",
    "c29fd543-3998-4ed5-bbec-0b544c23b091",
    "fc128752-74de-4529-8fa1-9dd98dcf6761",
    "bceedfc7-97df-47be-b069-5d5b7a09b879",
    "b9a9662b-e294-4350-90a2-8e630c6baccc",
    "5f4b0783-ba50-4d49-b622-fef269a98023",
    "fb8dc7db-b05b-49cc-afe9-4d26dd225b7e",
    "2468f3fc-9430-4369-8686-bb50457812af",
    "fa930380-3c77-45b7-8110-8fbc4bc121ef",
    "74ba85f4-b0fc-472f-a4ae-b213c5932916",
    "6f9627d5-7fda-4c68-9343-46a767696e24",
}

local failedJobsFile = "iddumper.json"
local failedJobs = {}

if isfile(failedJobsFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(failedJobsFile))
    end)
    if success and type(data) == "table" then
        failedJobs = data
    else
        failedJobs = {}
        writefile(failedJobsFile, "{}")
    end
else
    failedJobs = {}
    writefile(failedJobsFile, "{}")
end

local function saveFailedJob(jobId)
    failedJobs[jobId] = true
    writefile(failedJobsFile, HttpService:JSONEncode(failedJobs))
end

local function sendWebhook(title, fields, color)
    local req = (syn and syn.request) or http_request or request
    if not req then return end

    local body = {
        embeds = {{
            title = title,
            color = color or 65280,
            fields = fields,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }

    pcall(function()
        req({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end)
end

while task.wait(1.5) do
    for _, jobId in ipairs(jobList) do
        if jobId == currentJobId or failedJobs[jobId] then
            sendWebhook("Skipping Job", {
                { name = "JobId", value = "`" .. jobId .. "`", inline = false },
                { name = "Reason", value = jobId == currentJobId and "Current Job" or "Previously Failed", inline = false }
            }, 0x95A5A6) 
        else
            sendWebhook("Attempting Teleport", {
                { name = "Target JobId", value = "`" .. jobId .. "`", inline = false }
            }, 0x00FFFF) 

            local success, err = pcall(function()
                queue_on_teleport([[
                    repeat task.wait() until game:IsLoaded()
                    local sg = game:GetService("StarterGui")
                    local HttpService = game:GetService("HttpService")
                    local webhook = "]] .. webhookUrl .. [["

                    if not _G.__JOIN_WEBHOOK_SENT then
                        _G.__JOIN_WEBHOOK_SENT = true
                        pcall(function()
                            local x = require(game:GetService("ReplicatedStorage").Data.EventShopData)
                            local candyChance = x["Candy Blossom"] and x["Candy Blossom"].StockChance or "?"
                            local jobId = game.JobId
                            local placeVer = game.PlaceVersion

                            local embed = {
                                embeds = {{
                                    title = "Successfully Joined Server",
                                    color = 0x2ECC71,
                                    fields = {
                                        { name = "JobId", value = "`" .. jobId .. "`", inline = false },
                                        { name = "Place Version", value = "`" .. tostring(placeVer) .. "`", inline = true },
                                        { name = "Candy Blossom Chance", value = "`" .. tostring(candyChance) .. "%`", inline = true }
                                    },
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                }}
                            }

                            local req = (syn and syn.request) or http_request or request
                            if req then
                                req({
                                    Url = webhook,
                                    Method = "POST",
                                    Headers = {["Content-Type"] = "application/json"},
                                    Body = HttpService:JSONEncode(embed)
                                })
                            end

                            sg:SetCore("SendNotification", {
                                Title = "Teleport Success",
                                Text = "Candy Blossom Chance: " .. tostring(candyChance) .. "%",
                                Duration = 6
                            })
                        end)
                    end
                ]])

                TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
            end)

            if err then
                local reason = tostring(err)
                sendWebhook("Teleport Failed", {
                    { name = "JobId", value = "`" .. jobId .. "`", inline = false },
                    { name = "Reason", value = "`" .. reason .. "`", inline = false }
                }, 0xE74C3C) 

                if reason:lower():find("server is full") then
                    saveFailedJob(jobId)
                end
            end
        end
    end
end
