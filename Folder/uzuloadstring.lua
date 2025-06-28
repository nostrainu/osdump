getgenv().key = "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"

getgenv().get_github_file = function(file)
    local token = key

    local user = "uzu01"
    local repo = "private"
    local url = ("https://api.github.com/repos/%*/%*/contents/%*%22):format(user, repo, file)

    local auth = crypt.base64.encode(("%:%"):format(user, token))
    local headers = {["Authorization"] = ("Basic %*"):format(auth)}
    local result = game:GetService("HttpService"):JSONDecode(request({Url = url, Method = "GET", Headers = headers}).Body)

    local link =  rawget(result, "download_url")
    local succ, res = pcall(function()
        return game:HttpGet(link)
    end)

    if not link then print("wrong key", file) return end
    if not succ then task.wait(1) return get_github_file(file) end
    return loadstring(res)()
end

get_github_file("init.lua") 
