local AUTHOR    = "MSK-Scripts"
local NAME      = "VERSIONS"
local FILE      = "Fuel.json"

local RESOURCE_NAME     = "msk_fuel"
local NAME_COLORED      = "[^2"..GetCurrentResourceName().."^0]"
local GITHUB_API        = "https://raw.githubusercontent.com/%s/%s/main/%s"
local DOWNLOAD          = "https://github.com/MSK-Scripts/%s/releases/tag/v%s"

local PrintCompatibleScripts = function()
    local EngineToggle = { name = 'msk_enginetoggle', label = ("^3[%s]^0"):format('msk_enginetoggle') }

    if (GetResourceState(EngineToggle.name) == "started") then
        print(("%s Script %s was found and is running!"):format(NAME_COLORED, EngineToggle.label))
    elseif (GetResourceState(EngineToggle.name) == "stopped") then
        print(("%s Script %s was found but is stopped, please start the Script!"):format(NAME_COLORED, EngineToggle.label))
    elseif (GetResourceState(EngineToggle.name) == "missing") then
        print(("%s Script %s was not found, please make sure that the Script is started!"):format(NAME_COLORED, EngineToggle.label))
    end
end

----------------------------------------------------------------
-- Semantic version comparison.
--
-- Splitting on '.' and running tonumber over the pieces breaks the moment a
-- version carries a pre-release tag: '1.2.0-beta.1' splits into
-- {'1', '2', '0-beta', '1'}, tonumber('0-beta') is nil, and comparing nil to a
-- number is a hard error.  So the tag is separated out before comparing.
--
-- SemVer rule: a version WITH a pre-release tag sorts BEFORE the same version
-- without one. 1.2.0-beta.1 is older than 1.2.0 and newer than 1.1.1.
----------------------------------------------------------------

---@param version string
---@return table core, string|nil tag
local function parseVersion(version)
    local core, tag = tostring(version or ''):match('^([^-]*)-?(.*)$')
    local numbers = {}

    for piece in tostring(core):gmatch('[^%.]+') do
        numbers[#numbers + 1] = tonumber(piece) or 0
    end

    return numbers, (tag ~= '' and tag or nil)
end

---@return number -1 when `a` is older, 0 when equal, 1 when `a` is newer
function CompareVersions(a, b)
    local coreA, tagA = parseVersion(a)
    local coreB, tagB = parseVersion(b)

    for i = 1, math.max(#coreA, #coreB) do
        local left, right = coreA[i] or 0, coreB[i] or 0

        if left ~= right then
            return left < right and -1 or 1
        end
    end

    -- Same core: the one carrying a pre-release tag is the older of the two.
    if tagA and not tagB then return -1 end
    if tagB and not tagA then return 1 end
    if tagA ~= tagB then return tagA < tagB and -1 or 1 end

    return 0
end

VersionChecker = function()
    SetTimeout(1000, function()
        if RESOURCE_NAME ~= GetCurrentResourceName() then
            CreateThread(function()
                while true do
                    print(("%s [^3WARNING^0] ^3This resource should not be renamed! This can lead to errors. Please rename it to '%s'"):format(NAME_COLORED, RESOURCE_NAME))
                    Wait(5000)
                end
            end)
        end

        PerformHttpRequest(GITHUB_API:format(AUTHOR, NAME, FILE), function(status, response, headers)
            if status ~= 200 then
                return print(("%s [^1ERROR^0] ^1Version Check failed! Http Error: %s^0"):format(NAME_COLORED, status))
            end

            PrintCompatibleScripts()

            local response = json.decode(response)
            local latestVersion = response[1].version
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

            if currentVersion == latestVersion then
                return Config.VersionChecker and print(("%s ^2✓ Resource is Up to Date^0 - ^5Current Version: ^2%s^0"):format(NAME_COLORED, currentVersion))
            end

            local comparison = CompareVersions(currentVersion, latestVersion)

            if comparison < 0 then
                print(("%s [^3Update Available^0] ^3An Update is available for %s! ^0[^5Current Version: ^1%s^0 - ^5Latest Version: ^2%s^0]\r\n%s ^5Download:^4 %s ^0")
                :format(NAME_COLORED, RESOURCE_NAME, currentVersion, latestVersion, NAME_COLORED, DOWNLOAD:format(AUTHOR, RESOURCE_NAME)))

                for i = 1, #response do
                    if response[i].version == currentVersion then break end

                    if response[i].changelogs then
                        print(("%s [^3Changelogs v%s^0]"):format(NAME_COLORED, response[i].version))

                        for k = 1, #response[i].changelogs do
                            print(('%s %s'):format(NAME_COLORED, response[i].changelogs[k]))
                        end
                    end
                end
            elseif comparison > 0 and Config.VersionChecker then
                print(("%s ^3Pre-release version detected! ^0[^5Current Version: ^3%s^0 - ^5Latest Release: ^2%s^0] - ^3You can ignore this message!^0"):format(NAME_COLORED, currentVersion, latestVersion))
            end
        end)
    end)
end
VersionChecker()
