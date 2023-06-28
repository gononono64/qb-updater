local function DownloadCommand(zipPath, downloadUrl)
    local downloadCMD = string.format("curl -L -o \"%s\" \"%s\"", zipPath, downloadUrl)
    local downloadHandle = io.popen(downloadCMD)
    local downloadResult = downloadHandle:read("*a")
    downloadHandle:close()
    return downloadResult
end

local function UnpackCommand(zipPath, tempZipFolder)
    local unpackCMD = string.format("tar -xf \"%s\" -C \"%s\"", zipPath, tempZipFolder)
    local unpackHandle = io.popen(unpackCMD)
    local unpackResult = unpackHandle:read("*a")
    unpackHandle:close()
    return unpackResult
end

local function DeleteResourceCommand(path)
    local deleteResourceCMD = string.format("if exist \"%s\" rmdir /s /q \"%s\"", path, path)
    local deleteResourceHandle = io.popen(deleteResourceCMD)
    local deleteResourceResult = deleteResourceHandle:read("*a")
    deleteResourceHandle:close()
    return deleteResourceResult
end

local function RenameAndMoveCommand(tempZipFolder, path)
    local renameAndMoveCMD = string.format("move \"%s\" \"%s\"", tempZipFolder, path)
    local renameAndMoveHandle = io.popen(renameAndMoveCMD)
    local renameAndMoveResult = renameAndMoveHandle:read("*a")
    renameAndMoveHandle:close()
    return renameAndMoveResult
end

local function CleanUpCommand(zipPath)
    local cleanupCMD = string.format("del /f \"%s\"", zipPath)
    local cleanupHandle = io.popen(cleanupCMD)
    local cleanupResult = cleanupHandle:read("*a")
    cleanupHandle:close()
    return cleanupResult
end

local function MoveIgnoredToUnzipPath(ignorePaths, unzipPath)
    local moveResult = ""
    for _, v in ipairs(ignorePaths or {}) do
        local ignoredPath = v.path
        local tempPath = unzipPath .. '\\' .. v.relativePath
        moveResult = RenameAndMoveCommand(ignoredPath, tempPath)
    end
    return moveResult
end


local function DownloadAndInstallGitHubRepo(url, branch, path, ignorePaths, useLatestReleaseLink, cb)
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    
    local downloadUrl = string.format("https://github.com/%s/%s/archive/refs/heads/%s.zip", username, repository, branch)
    local tempFolder = os.getenv("temp")
    local zipPath = tempFolder .. '\\' .. repository .. '.zip'
    local tempZipFolder = tempFolder .. '\\' .. repository .. '-' .. branch
    if useLatestReleaseLink then
        downloadUrl = string.format("https://github.com/%s/%s/releases/latest/download/%s.zip", username, repository, repository)
        tempZipFolder = tempFolder .. '\\' .. repository
    end
    -- Download the file
    

    local downloadResult = DownloadCommand(zipPath, downloadUrl) -- Download the resource and place into temp folder
    if not downloadResult then return end  

    local unpackResult = UnpackCommand(zipPath, tempFolder) -- Unpack the resource into temp folder
    if not unpackResult then return end

    local ignoreResult = MoveIgnoredToUnzipPath(ignorePaths, tempZipFolder)
    if not ignoreResult then return end

    local deleteResourceResult = DeleteResourceCommand(path)
    if not deleteResourceResult then return end

    local renameAndMoveResult = RenameAndMoveCommand(tempZipFolder, path)
    if not renameAndMoveResult then return end

    local cleanupResult = CleanUpCommand(zipPath)
    if not cleanupResult then return end

    local result = [[
        ]] .. downloadResult .. [[
        ]] .. unpackResult .. [[
        ]] .. deleteResourceResult .. [[
        ]] .. renameAndMoveResult .. [[
        ]] .. cleanupResult .. [[
    ]]
    result = result:gsub("%s+", "")
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
        if cb and type(cb) == "function" then
            cb(result)
        end
        return true
    end
end

local function GetFileTextFromGitHubRepo(url, branch, filename, cb)
    if not cb or type(cb) ~= "function" then return end
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    local fileURL = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", username, repository, branch, filename)
    PerformHttpRequest(fileURL, function(response, responseText, responseHeaders)
        cb(response, responseText, responseHeaders)
    end)
end

local function GetVersionNumberFromFile(filePath)
    local file = io.open(filePath, "r")
    if not file then return end

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

local function GenerateIgnoredPaths(resourcePath, resourceName)
    local ignorePaths = {}
    local configResource = Config.Resources[resourceName]
    if not configResource then return ignoredPaths end 

    local configIgnore = configResource.ignore
    if not configIgnore then return ignoredPaths end
    
    for _, ignoredPath in ipairs(configIgnore) do
        if string.find(ignoredPath, "*", 1, true) then
            local pattern = string.gsub(ignoredPath, "*", ".*")
            local files = io.popen("dir /b /s " .. resourcePath .. "\\" .. pattern):lines()
            for file in files do
                ignorePaths[#ignorePaths + 1] = {
                    path = file,
                    relativePath = string.gsub(file, resourcePath .. "\\", "")
                }

            end
        else
            local path = resourcePath .. '\\' .. ignoredPath
            ignorePaths[#ignorePaths + 1] = {
                path = path,
                relativePath = ignoredPath,
            }
        end
    end

    return ignorePaths
end

local couldNotPullFXManifest = {}
local function RetrieveResourceVersionAndDownload(resourceName, resourcePath, branch, url, useLatestReleaseLink, cb)
    local resourceVersionFilePath = string.format("%s\\fxmanifest.lua", resourcePath)
    local resourceVersion = GetVersionNumberFromFile(resourceVersionFilePath)
    branch = branch or "main"
    GetFileTextFromGitHubRepo(url, branch, "fxmanifest.lua", function(error, responseText, responseHeaders)
        if error ~= 200 then
            print("Error getting fxmanifest.lua for " .. resourceName .. " from GitHub!")
            couldNotPullFXManifest[resourceName] = true
            return
        end
        local versionNumber = responseText:match("version%s+'([%d%.]+)'")
        
        if not versionNumber or not resourceVersion or CompareVersionNumbers(versionNumber, resourceVersion) > 0 then 
            local ignoredPaths = GenerateIgnoredPaths(resourcePath, resourceName)
            DownloadAndInstallGitHubRepo(url, branch, resourcePath, ignoredPaths, useLatestReleaseLink)
        end
    end)
end

local function UpdateServer(cb)
    local currentResourceName = string.gsub(GetCurrentResourceName(), " ", ""):lower()
    
    CreateThread(function()
        local fallbackPath = GetResourcePath(currentResourceName)
        if not fallbackPath then print("Error getting fallback path!") return end
        fallbackPath = string.gsub(fallbackPath, "//", "/")
        fallbackPath = string.gsub(fallbackPath, "/", "\\")
        

        for resourceName, v in pairs(Config.Resources) do
            local url = v.url
            local branch = v.branch or "main"
            local useLatestReleaseLink = v.useLatestReleaseLink
            local resourcePathRaw = GetResourcePath(resourceName) or ''
            if resourcePathRaw == '' then
                local pattern = 'qb%-updater'
                resourcePathRaw = string.gsub(fallbackPath, pattern, resourceName )                     
            end     
            
            if resourcePathRaw then 
                --C:/Users/User/AppData/Local/FiveM/FiveM.app/Contents/runtime/resources/[local]/qb-updater..//qb-updater

                --C:\\Users\\User\\AppData\\Local\\FXServer\\resources\\qb-updater\\qb-updater
                
                local resourcePath = string.gsub(resourcePathRaw, "//", "/")
                resourcePath = string.gsub(resourcePath, "/", "\\")
                RetrieveResourceVersionAndDownload( resourceName, resourcePath, branch, url, useLatestReleaseLink, cb)                
            end
            Wait(100)
        end  
        for resource, cNPFFXM in pairs(couldNotPullFXManifest) do
            if cNPFFXM then
                print("Could not pull fxmanifest.lua from " .. resource)
            end
        end
        couldNotPullFXManifest = {}
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



RegisterCommand('qb-update', function(source, args, rawCommand)
    local password = args[1]
    if Config.EnableAdditionalSecurity then
        assert(password, "No password provided!")
        assert(password == Config.Password, "Invalid password provided!")
    end
    UpdateServer()
end, true) 

RegisterCommand('qb-freshupdate', function(source, args, rawCommand)
    local password = args[1]
    if Config.EnableAdditionalSecurity then
        assert(password, "No password provided!")
        assert(password == Config.Password, "Invalid password provided!")
    end
    RemoveAllResources()
    UpdateServer()    
end, true)

RegisterCommand('qb-install', function(source, args, rawCommand)    
    local url = args[1]
    assert(url, "No URL provided!")
    
    local branch = args[2]
    local password = args[3]
    if not password then 
        if branch and branch == Config.Password then 
            password = branch
            branch = "main"
        end
    end 
      
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    assert(username and repository, "Invalid URL provided!")

    if not branch then
        local config = Config.Resources[repository]
        if config then
            branch = config.branch or "main"
        else
            branch = "main"
        end
    end

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
    RetrieveResourceVersionAndDownload( repository, resourcePath, branch, url, false)       
end, true)

RegisterCommand('qb-installrelease', function(source, args, rawCommand)
    local url = args[1]
    assert(url, "No URL provided!")
    
    local branch = args[2] or 'main'
    local password = args[3]
    if not password then 
        if branch and branch == Config.Password then 
            password = branch
            branch = 'main'
        end
    end 
      
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    assert(username and repository, "Invalid URL provided!")
    if not branch then
        local config = Config.Resources[repository]
        if config then
            branch = config.branch or "main"
        else
            branch = "main"
        end
    end

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
    RetrieveResourceVersionAndDownload(repository, resourcePath, branch, url, true)       
end, true)


local function TriggerSuggestion(src)
    TriggerClientEvent('chat:addSuggestion', src, '/qb-update', 'Update all qb resources', {
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-freshupdate', 'Remove all qb resources and update them', {
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-install', 'Download and soft-install GitHub resource', {
        { name="url", help="The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'" },
        { name="branch/password", help="[Branch] OPTIONAL: The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') [Password] OPTIONAL: The password set in qb-updater. *Required* if enabled in config.lua AND the resource is not already installed."},
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua AND the resource is not already installed." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-installrelease', 'Download and soft-install GitHub resource from latest release', {
        { name="url", help="The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'"},
        { name="branch/password", help="[Branch] OPTIONAL: The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') [Password] OPTIONAL: The password set in qb-updater. *Required* if enabled in config.lua AND the resource is not already installed."},
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua AND the resource is not already installed." },
    })
end
        

RegisterNetEvent('playerJoining', function(oldId)
    local src = source
    TriggerSuggestion(src)    
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerSuggestion(-1)
    end
end)
