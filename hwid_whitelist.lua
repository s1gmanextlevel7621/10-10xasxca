-- HWID Whitelist Script for Messi Hub
-- Run this script to register your HWID with your key

-- Initialize the script object
local script = {}
script.key = nil -- User will set this: script.key = "YOUR_KEY"

-- Configuration
local config = {
    title = "Messi Hub HWID Registration",
    version = "1.0.0",
    validation_url = "http://localhost:3000/validate", -- URL to validate keys with the Discord bot server
    webhook = "https://discord.com/api/webhooks/1354607933652205633/s4uJOX97aG83TJOY5u1muVDFLE4IFUPatvA4lVAiPuz74x5fDaOORZKSrP7talfY-AlJ" -- Discord webhook for logging
}

-- Load Fluent Library for UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Get HWID function (same as in main script for consistency)
local function getHWID()
    -- This is a simplified HWID generation
    -- In a real implementation, you would use more hardware identifiers
    local hwid = ""
    
    -- Try to get some unique identifiers
    local success, result = pcall(function()
        -- Get some hardware info that could be used to generate a unique ID
        local username = game:GetService("Players").LocalPlayer.Name
        local placeId = game.PlaceId
        local jobId = game.JobId
        local deviceInfo = game:GetService("RbxAnalyticsService"):GetClientId()
        
        -- Combine information to create a unique HWID
        return username .. "-" .. placeId .. "-" .. jobId .. "-" .. deviceInfo
    end)
    
    if success then
        hwid = result
    else
        -- Fallback to a less unique but still somewhat useful identifier
        hwid = game:GetService("Players").LocalPlayer.UserId .. "-" .. game.PlaceId
    end
    
    -- Hash the HWID to make it more secure
    local hashedHWID = ""
    for i = 1, #hwid do
        hashedHWID = hashedHWID .. string.byte(hwid, i)
    end
    
    return hashedHWID
 end

-- Register HWID function using HTTP request to the Discord bot server
local function registerHWID(key)
    if not key or type(key) ~= "string" then
        return false, "No key provided. Set script.key = \"YOUR_KEY\" before executing."
    end
    
    -- Get the HWID
    local hwid = getHWID()
    
    -- Create the request data
    local requestData = {
        key = key,
        hwid = hwid
    }
    
    -- Convert to JSON
    local jsonData = game:GetService("HttpService"):JSONEncode(requestData)
    
    -- Send HTTP request to validate the key
    local success, response = pcall(function()
        return game:GetService("HttpService"):PostAsync(
            config.validation_url,
            jsonData,
            Enum.HttpContentType.ApplicationJson
        )
    end)
    
    if success then
        -- Parse the response
        local responseData = game:GetService("HttpService"):JSONDecode(response)
        
        if responseData.success then
            return true, responseData.message
        else
            return false, responseData.message
        end
    else
        -- Error handling for HTTP request failure
        return false, "Failed to register HWID. Server may be offline. Error: " .. tostring(response)
    end
end

-- Register HWID and send to Discord webhook
local function registerHWIDAndNotify(key)
    -- Get the HWID
    local hwid = getHWID()
    
    -- Register HWID with server
    local success, message = registerHWID(key)
    
    -- Send notification to Discord webhook if available
    if config.webhook and config.webhook ~= "" then
        pcall(function()
            -- Create webhook data
            local webhookData = {
                content = "",
                embeds = {
                    {
                        title = "HWID Registration",
                        description = "A new HWID has been registered",
                        color = success and 65280 or 16711680, -- Green if success, red if failed
                        fields = {
                            {
                                name = "Key",
                                value = key,
                                inline = true
                            },
                            {
                                name = "HWID",
                                value = hwid,
                                inline = true
                            },
                            {
                                name = "Status",
                                value = success and "Success" or "Failed",
                                inline = true
                            },
                            {
                                name = "Message",
                                value = message,
                                inline = false
                            },
                            {
                                name = "Username",
                                value = game:GetService("Players").LocalPlayer.Name,
                                inline = true
                            },
                            {
                                name = "User ID",
                                value = tostring(game:GetService("Players").LocalPlayer.UserId),
                                inline = true
                            },
                            {
                                name = "Game",
                                value = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
                                inline = true
                            }
                        },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }
                }
            }
            
            -- Send webhook
            game:GetService("HttpService"):PostAsync(
                config.webhook,
                game:GetService("HttpService"):JSONEncode(webhookData),
                Enum.HttpContentType.ApplicationJson
            )
        end)
    end
    
    return success, message
end

-- Simple execution function
local function executeRegistration()
    if not script.key or script.key == "" then
        print("[ERROR] No key provided. Please set script.key = \"YOUR_KEY\" before executing.")
        print("Example usage: script.key = \"MESSI-HUB-1234-ABCD\"")
        return false
    end
    
    print("[INFO] Starting HWID registration with key: " .. script.key)
    print("[INFO] Your HWID: " .. getHWID())
    
    -- Register HWID
    local success, message = registerHWIDAndNotify(script.key)
    
    if success then
        print("[SUCCESS] " .. message)
        print("[INFO] You can now use the main Messi Hub script without entering your key.")
    else
        print("[ERROR] " .. message)
    end
    
    return success
end

-- Execute the script
do
    executeRegistration()
end

-- Return the script object for user interaction
return script
