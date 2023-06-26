


local function DownloadAndInstallGitHubRepo(url, path)
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    local downloadUrl = string.format("https://github.com/%s/%s/archive/refs/heads/main.zip", username, repository)

    -- Download the file
    local tempFolder = os.getenv("temp")
    local zipPath = tempFolder .. '\\' .. repository .. '.zip'
    local tempZipFolder = tempFolder .. '\\' .. repository .. '-main'

    local downloadCMD = string.format("curl -L -o \"%s\" \"%s\"", zipPath, downloadUrl)
    local unpackCMD = string.format("tar -xf \"%s\" -C \"%s\"", zipPath, tempFolder)
    local deleteResourceCMD = string.format("if exist \"%s\" rmdir /s /q \"%s\"", path, path)
    local renameAndMoveCMD = string.format("move \"%s\" \"%s\"", tempZipFolder, path)
    local cleanupCMD = string.format("del /f \"%s\"", zipPath)

    local downloadHandle = io.popen(downloadCMD)
    local downloadResult = downloadHandle:read("*a")
    downloadHandle:close()
    if not downloadResult then return end

    local unpackHandle = io.popen(unpackCMD)
    local unpackResult = unpackHandle:read("*a")
    unpackHandle:close()
    if not unpackResult then return end

    local deleteResourceHandle = io.popen(deleteResourceCMD)
    local deleteResourceResult = deleteResourceHandle:read("*a")
    deleteResourceHandle:close()

    local renameAndMoveHandle = io.popen(renameAndMoveCMD)
    local renameAndMoveResult = renameAndMoveHandle:read("*a")
    renameAndMoveHandle:close()

    local cleanupHandle = io.popen(cleanupCMD)
    local cleanupResult = cleanupHandle:read("*a")
    cleanupHandle:close()

    local result = [[
        ]] .. downloadResult .. [[
        ]] .. unpackResult .. [[
        ]] .. deleteResourceResult .. [[
        ]] .. renameAndMoveResult .. [[
        ]] .. cleanupResult .. [[
    ]] --downloadResult unpackResult and deleteResourceResult and renameAndMoveResult and cleanupResult
    if result then 
        print(
            "\n\t============================= Downloaded and Installed: " .. repository .. " =============================",
            "\n\tDownload URL:", downloadUrl,
            "\n\tDownload Path:", zipPath,
            "\n\tUnpack Path:", tempZipFolder,
            "\n\tMove Path:", path,
            "\n\tResult:", result,
            "\n\t=================================================================================================="
        )

        return true
    end
end

local function GetFileTextFromGitHubRepo(url, filename, cb)
    if not cb or type(cb) ~= "function" then
        return
    end
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    local fileURL = string.format("https://raw.githubusercontent.com/%s/%s/main/%s", username, repository, filename)
    PerformHttpRequest(fileURL, function(response, responseText, responseHeaders)
        cb(response, responseText, responseHeaders)
    end)
end

local function GetVersionNumberFromFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return
    end
    local fileContents = file:read("*a")
    file:close()
    local versionNumber = fileContents:match("version%s+'([%d%.]+)'")
    return versionNumber
end

local function CompareVersionNumbers(version1, version2)
    local version1Parts = {}
    for part in version1:gmatch("%d+") do
        table.insert(version1Parts, tonumber(part))
    end
    local version2Parts = {}
    for part in version2:gmatch("%d+") do
        table.insert(version2Parts, tonumber(part))
    end
    for i = 1, math.max(#version1Parts, #version2Parts) do
        local part1 = version1Parts[i] or 0
        local part2 = version2Parts[i] or 0
        if part1 > part2 then
            return 1
        elseif part1 < part2 then
            return -1
        end
    end
    return 0
end

local couldNotPullFXManifest = {}
local function UpdateServer()
    local currentResourceName = string.gsub(GetCurrentResourceName(), " ", ""):lower()
    
    Citizen.CreateThread(function()
        local fallbackPath = GetResourcePath(currentResourceName)
        if not fallbackPath then print("Error getting fallback path!") return end
        fallbackPath = string.gsub(fallbackPath, "//", "/")
        fallbackPath = string.gsub(fallbackPath, "/", "\\")
        

        for resourceName, url in pairs(Config.Resources) do
            local resourcePathRaw = GetResourcePath(resourceName) or ''
            if resourcePathRaw == '' then
                local pattern = 'qb%-updater'
                resourcePathRaw = string.gsub(fallbackPath, pattern, resourceName )                     
            end     
            
            if resourcePathRaw then 
                local resourcePath = string.gsub(resourcePathRaw, "//", "/")
                resourcePath = string.gsub(resourcePath, "/", "\\")
                local resourceVersionFilePath = string.format("%s/fxmanifest.lua", resourcePath)
                local resourceVersion = GetVersionNumberFromFile(resourceVersionFilePath)

                GetFileTextFromGitHubRepo(url, "fxmanifest.lua", function(error, responseText, responseHeaders)
                    if error ~= 200 then
                        print(string.format("Error getting file from %s: %s", url, error))
                        couldNotPullFXManifest[resourceName] = true
                        return
                    end
                    local versionNumber = responseText:match("version%s+'([%d%.]+)'")
                    
                    if not versionNumber or not resourceVersion or CompareVersionNumbers(versionNumber, resourceVersion) > 0 then 
                        DownloadAndInstallGitHubRepo(url, resourcePath)
                    end
                end)
            end
            Wait(100)
        end  
        for resource, cNPFFXM in pairs(couldNotPullFXManifest) do
            if cNPFFXM then
                print("Could not pull fxmanifest.lua from " .. resource)
            end
        end
        print("All registered resources updated!")  
    end)    
end

local function RemoveResouce(resourceName)
    local resourcePathRaw = GetResourcePath(resourceName)
    if not resourcePathRaw then return end

    local resourcePath = string.gsub(resourcePathRaw, "//", "/")
    resourcePath = string.gsub(resourcePath, "/", "\\")
    
    local removeCMD = string.format("rmdir /s /q \"%s\"", resourcePath)
    local handle = io.popen(removeCMD)
    local result = handle:read("*a")
    handle:close()
    if result then 
        print(
            "\n\t============================= Removed: " .. resourceName .. " =============================",
            "\n\tPath:", resourcePath,
            "\n\tResult:", result,
            "\n\t=================================================================================================="
        )
        return true
    end

    return false 
end

local RemoveAllResources = function()
    for resourceName, url in pairs(Config.Resources) do
        RemoveResouce(resourceName)
    end
    print("All registered resources removed!")
end


RegisterCommand('qb-update', function()
    UpdateServer()
end, true) 

RegisterCommand('qb-freshupdate', function()
    RemoveAllResources()
    UpdateServer()    
end, true)

RegisterCommand('qb-install', function(source, args, rawCommand)
    local url = args[1]        
    local password = args[2]
    assert(url, "No URL provided!")    
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    assert(username and repository, "Invalid URL provided!")
    local resourcePath = GetResourcePath(repository)

    if Config.EnableAdditionalSecurity and not resourcePath then
        assert(password, "No password provided!")
        assert(password == Config.Password, "Invalid password provided!")
    end
    if not resourcePath then
        resourcePath = GetResourcePath(GetCurrentResourceName())
        assert(resourcePath, "Error getting fallback path!")
        local pattern = 'qb%-updater'
        resourcePath = string.gsub(resourcePath, pattern, repository)   
    end
    resourcePath = string.gsub(resourcePath, "//", "/")
    resourcePath = string.gsub(resourcePath, "/", "\\")
    print("Installing " .. repository .. " to " .. resourcePath)
    DownloadAndInstallGitHubRepo(url, resourcePath)
end, true)


CreateThread(function()
    TriggerClientEvent('chat:addSuggestion', -1, '/qb-update', 'Update all qb resources')
    TriggerClientEvent('chat:addSuggestion', -1, '/qb-freshupdate', 'Remove all qb resources and update them')
    TriggerClientEvent('chat:addSuggestion', -1, '/qb-install', 'Download and soft-install GitHub resource', {
        { name="url", help="The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'" },
        { name="password", help="Required if enabled in config.lua and the resource is not already installed." }
    })

end)



