local Helpers = {}
local cached_replacements = {} -- Cache for replacements
local prev_config_keys_list = {} -- Cache for previous config keys
local current_config_keys_list = {} -- Cache for current config keys
local current_aliases_list = {} -- Cache for current aliases
local current_active_devices = {} -- Cache for current active devices

-- Function to get replacements (generates if cache is empty)
function Helpers.getReplacements()
    -- Simple check - if cache has any content, use it
    if cached_replacements and next(cached_replacements) then
        return cached_replacements
    end
    
    -- Cache doesn't exist or is empty, generate it
    return Helpers.generateReplacements()
end

-- Function to generate and cache replacements based on current player and game state
function Helpers.generateReplacements()
    local replacements = {}
    
    -- Check if player is logged in
    if not windower.ffxi.get_info().logged_in then
        Helpers.addToChat("Player not logged in. Cannot generate replacements.")
        cached_replacements = {}
        return cached_replacements
    end
    
    local player = windower.ffxi.get_player()
    if not player then
        Helpers.addToChat("Unable to get player information.")
        cached_replacements = {}
        return cached_replacements
    end
    
    -- Add player-based replacements using ternary-like pattern
    replacements["{player_name}"] = player.name and player.name or ''
    replacements["{main_job}"] = player.main_job and player.main_job:upper() or ''
    replacements["{sub_job}"] = player.sub_job and player.sub_job:upper() or ''
    replacements["{full_job}"] = player.main_job and (player.main_job:upper() .. (player.sub_job and ("_" .. player.sub_job:upper()) or "")) or ''
    
    -- Load custom replacements from external file
    custom_replacements_file = files.new('data\\custom_replacements.lua')
    if not files.exists('data\\custom_replacements.lua') then
        --Helpers.addToChat("No file found '" .. file_path .. "'.")
        custom_replacements_file:write('return '..T({}):tovstring()) -- Create a default file if it doesn't exist
    end
    package.loaded['data/custom_replacements'] = nil
    local custom_replacements = require('data/custom_replacements')
    if custom_replacements and type(custom_replacements) == 'table' then
        if Helpers.validateTableData(custom_replacements, false, false, true) then -- Allow empty table
            for key, value in pairs(custom_replacements) do
                replacements[key] = value
            end
        else
            Helpers.addToChat("Invalid custom replacements loaded from file. Using only default replacements.")
        end
    end
    
    -- Validate the generated replacements table
    if not Helpers.validateTableData(replacements, false, false, true) then -- Allow empty table
        Helpers.addToChat("Generated replacements table is invalid.")
        cached_replacements = {}
        return cached_replacements
    end
    
    -- Cache the replacements
    cached_replacements = replacements
    --Helpers.addToChat("Replacements generated and cached successfully.")
    return cached_replacements
end

-- Function to get cached replacements
function Helpers.getCachedReplacements()
    return cached_replacements
end

-- Function to clear cached replacements
function Helpers.clearCachedReplacements()
    cached_replacements = {}
    Helpers.addToChat("Cached replacements cleared.")
end

function Helpers.displayAvailableReplacements()
    local replacements = Helpers.getReplacements()
    
    if not replacements or not next(replacements) then
        Helpers.addToChat("No replacements available.")
        return
    end
    
    Helpers.addToChat("Available replacements:")
    for key, value in pairs(replacements) do
        Helpers.addToChat(string.format("%s: %s", key, value))
    end
end

-- Function to replace keys in string using cached replacements (case-insensitive)
function Helpers.replaceKeysInString(input_string)
    if not input_string or type(input_string) ~= 'string' then
        return input_string
    end
    
    local replacements = Helpers.getReplacements()
    
    -- Simple check instead of full validation
    if not replacements or not next(replacements) then
        return input_string
    end
    
    local result = input_string
    
    -- Sort keys by length (longest first) to avoid partial replacements
    local sorted_keys = {}
    for key, _ in pairs(replacements) do
        table.insert(sorted_keys, key)
    end
    table.sort(sorted_keys, function(a, b) return #a > #b end)
    
    -- Replace each key with its corresponding value (case-insensitive)
    for _, key in ipairs(sorted_keys) do
        local value = replacements[key]
        if type(value) == 'string' then
            -- Escape special pattern characters in the key
            local escaped_key = key:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
            
            -- Create a case-insensitive pattern by replacing each letter with [Aa] format
            local case_insensitive_pattern = escaped_key:gsub("(%a)", function(c)
                return "[" .. c:upper() .. c:lower() .. "]"
            end)
            
            result = result:gsub(case_insensitive_pattern, value)
        end
    end
    
    return result
end

function Helpers.load_default_device_aliases(device_code)
    --Helpers.addToChat(debug.getinfo(1, "n").name .. " for device code: " .. device_code)
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    local device_default_path = 'devices/' .. device_code .. '/default_aliases.lua'
    if not files.exists(device_default_path) then
        Helpers.addToChat("No default aliases found for device '" .. device_code .. "'.")
        return
    end
    --Helpers.addToChat("Loading defaults from " .. device_default_path)
    --package.loaded['devices/' .. device_code .. '/default_aliases'] = nil
    return require('devices/' .. device_code .. '/default_aliases')
end

function Helpers.load_file_aliases(device_code, file_name, key, create_if_not_exists)
    local file_aliases = {}
    --Helpers.addToChat(debug.getinfo(1, "n").name .. " for device code: " .. device_code .. " and file: " .. file_name .. " and key: " .. key)
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return file_aliases
    end
    if not file_name or file_name == '' then
        Helpers.addToChat("No file name provided.")
        return file_aliases
    end
    if not key or key == '' then
        key = 'default'
    end
    local file_path = 'devices\\' .. device_code .. '\\' .. file_name .. '.lua'
    aliases_file = files.new(file_path)
    if not files.exists(file_path) then
        --Helpers.addToChat("No file found '" .. file_path .. "'.")
        if not create_if_not_exists then
            return {}
        end
        local default_aliases_file = {
            ['default'] = {}
        }
        aliases_file:write('return '..T(default_aliases_file):tovstring()) -- Create a default file if it doesn't exist
    end
    --package.loaded['devices/' .. device_code .. '/' .. file_name] = nil
    file_aliases = require('devices/' .. device_code .. '/' .. file_name)
    if not file_aliases or not file_aliases[key] then
        --Helpers.addToChat("No aliases found for key '" .. key .. "' in file '" .. file_name .. "'.")
        return {}
    end
    return file_aliases[key]
end

function Helpers.load_all_aliases(device_code, config_key)
    local all_aliases = {}
    --Helpers.addToChat(debug.getinfo(1, "n").name .. " for device code: " .. device_code .. " and config_key: " .. config_key)
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        --Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return all_aliases
    end
    -- Load file name list based on the device code and player info
    local file_name_list = {
        {
            file_name = 'general',
            create_if_not_exists = true
        }
    }
    if windower.ffxi.get_info().logged_in then
        table.insert(file_name_list, {
            file_name = windower.ffxi.get_player().main_job:upper(),
            create_if_not_exists = settings.options.job_files_create_if_not_exists
        })
        if windower.ffxi.get_player().sub_job then
            table.insert(file_name_list, {
                file_name = windower.ffxi.get_player().main_job:upper()..'_'..windower.ffxi.get_player().sub_job:upper(),
                create_if_not_exists = settings.options.job_files_create_if_not_exists
            })
        end
        table.insert(file_name_list, {
            file_name = windower.ffxi.get_player().name:lower(),
            create_if_not_exists = settings.options.user_files_create_if_not_exists
        })
        table.insert(file_name_list, {
            file_name = windower.ffxi.get_player().name:lower()..'_'..windower.ffxi.get_player().main_job:upper(),
            create_if_not_exists = settings.options.user_files_create_if_not_exists and settings.options.job_files_create_if_not_exists
        })
        if windower.ffxi.get_player().sub_job then
            table.insert(file_name_list, {
                file_name = windower.ffxi.get_player().name:lower()..'_'..windower.ffxi.get_player().main_job:upper()..'_'..windower.ffxi.get_player().sub_job:upper(),
                create_if_not_exists = settings.options.user_files_create_if_not_exists and settings.options.job_files_create_if_not_exists
            })
        end
    end
    -- Load aliases from each file in the list
    for _, file_info in ipairs(file_name_list) do
        --Helpers.addToChat("Loading aliases from file: " .. file_info.file_name)
        local file_aliases = Helpers.load_file_aliases(device_code, file_info.file_name, config_key, file_info.create_if_not_exists)
        -- merge all aliases into a single table
        for alias_key, alias_value in pairs(file_aliases) do
            --Helpers.addToChat("Loading alias '" .. alias_key .. "' with value '"..alias_value.."' from file '" .. file_info.file_name .. "'.")
            all_aliases[alias_key:lower()] = alias_value
        end
    end
    return all_aliases
end

function Helpers.validateTableData(table_data, skip_check_is_nil, skip_check_is_table, skip_check_is_empty)
    -- Early return for nil check
    if not skip_check_is_nil and table_data == nil then
        --Helpers.addToChat("Debug: Table data is nil.")  -- Keep this for now
        return false
    end

    -- Check if the input is a table
    if not skip_check_is_table and type(table_data) ~= 'table' then
        --Helpers.addToChat("Debug: Table data is not a table, it's " .. type(table_data)) -- Keep this for now
        return false
    end

    -- Check if the table is empty (only if table_data is not nil)
    if not skip_check_is_empty and table_data ~= nil and next(table_data) == nil then
        --Helpers.addToChat("Debug: Table data is empty.")  -- Keep this for now
        return false
    end
    return true
end

-- Sorts a table by numeric parts inside keys (any number count), then alphabetical
-- Input: table_data = { key = value, ... }
-- Output: array of {key=key, value=value} sorted accordingly
function Helpers.sort_table_by_key_numbers(table_data)
    -- return an empty table if the input is not a table or empty or nil
    if not Helpers.validateTableData(table_data, false, false, true) then
        Helpers.addToChat("Invalid table data provided for sorting.")
        return {}
    end

    -- Extract all numbers from a key as an array of numbers
    local function extract_numbers(key)
        local nums = {}
        for num in key:gmatch("%d+") do
            table.insert(nums, tonumber(num))
        end
        return nums
    end

    -- Compare two number arrays element-wise
    local function compare_numbers(aNums, bNums)
        local len = math.min(#aNums, #bNums)
        for i = 1, len do
            if aNums[i] < bNums[i] then
                return true
            elseif aNums[i] > bNums[i] then
                return false
            end
        end
        return #aNums < #bNums
    end

    -- Prepare sortable list
    local sortable_list = {}
    for k, v in pairs(table_data) do
        table.insert(sortable_list, {
            key = k,
            value = v,
            nums = extract_numbers(k),
        })
    end

    -- Sort function
    table.sort(sortable_list, function(a, b)
        if a.key == b.key then return false end
        if compare_numbers(a.nums, b.nums) then
            return true
        elseif compare_numbers(b.nums, a.nums) then
            return false
        else
            return a.key < b.key
        end
    end)

    -- Remove 'nums' before returning if you want just key/value pairs
    for _, item in ipairs(sortable_list) do
        item.nums = nil
    end

    return sortable_list
end

function Helpers.listTable(table_data, sort_by_key)
    if sort_by_key then
        --Helpers.addToChat("Sort By Key")
        local table_to_list = Helpers.sort_table_by_key_numbers(table_data)
        for _, item in ipairs(table_to_list) do
            Helpers.addToChat(" - " .. item.key .. ": " .. item.value)
        end
    else
        --Helpers.addToChat("Sort By Value")
        local table_to_list = {}
        for k, v in pairs(table_data) do
            table.insert(table_to_list, { key = k, value = v })
        end
        table.sort(table_to_list, function(a, b)
            return a.value < b.value
        end)
        for _, item in ipairs(table_to_list) do
            Helpers.addToChat(" - " ..item.key .. ": " .. item.value)
        end
    end
end

function Helpers.addToChat(message)
    windower.add_to_chat(8, '['..(_addon.name):color(220)..'] '..message) -- 8 is the color code for yellow
end

function Helpers.setAliases(device_code, aliases)
    if not Helpers.validateTableData(aliases) then
        Helpers.addToChat("Invalid aliases provided.")
        return
    end
    local aliases_list = Helpers.sort_table_by_key_numbers(aliases)
    local current_aliases_list = {}
    for _, alias in ipairs(aliases_list) do
        --Helpers.addToChat("DEBUG: Key=" .. tostring(alias.key) .. ", Type=" .. type(alias.value) .. ", Value=" .. tostring(alias.value))
        if type(alias.key) ~= 'string' then
            Helpers.addToChat("Alias Key '" .. alias.key .. "' is not a string.")
            return
        end
        if alias.key == nil or alias.key == "" then
            Helpers.addToChat("Alias key is empty.")
            return
        end
        if alias.value == nil then
            Helpers.addToChat("Missing alias for key '" .. alias.key .. "'.")
            return
        end
        if type(alias.value) ~= 'string' then
            Helpers.addToChat("Alias for key '" .. alias.key .. "' is not a string.")
            Helpers.addToChat("Value: " .. tostring(alias.value))
            return
        end
        local alias_value = Helpers.replaceKeysInString(alias.value)
        local alias_command = 'alias ' .. alias.key .. ' ' .. alias_value .. ' ;'
        --Helpers.addToChat("Assigning alias '" .. alias.key .. "' to command '" .. alias_value .. "'.")
        --Helpers.addToChat("Command: " .. alias_command)
        windower.send_command(alias_command)
        table.insert(current_aliases_list, {key = alias.key, value = alias_value})
    end
    Helpers.addAliasesListToCurrent(device_code, current_aliases_list)
    --Helpers.addToChat("Aliases have been assigned successfully.")
end

function Helpers.addConfigKeyToHistory(device_code, config_key)
    --Helpers.addToChat("Adding config key to history for device: " .. device_code .. " - Config Key: " .. config_key)
    if prev_config_keys_list[device_code] == nil then
        prev_config_keys_list[device_code] = {}
    end
    table.insert(prev_config_keys_list[device_code], config_key)
end

function Helpers.displayConfigKeysHistory(device_code)
    local list = prev_config_keys_list[device_code]
    if not list or #list == 0 then
        Helpers.addToChat("No config keys history for device " .. device_code)
        return
    end
    Helpers.addToChat("Config keys history for device " .. device_code .. ":")
    for i, config_key in ipairs(list) do
        Helpers.addToChat(i .. ": " .. config_key)
    end
end

function Helpers.popLastConfigKeyFromHistory(device_code)
    local list = prev_config_keys_list[device_code]
    if not list or #list == 0 then
        --Helpers.addToChat("No config keys history for device " .. device_code)
        return nil
    end
    return table.remove(list)
end

function Helpers.clearConfigKeysHistory(device_code)
    prev_config_keys_list[device_code] = nil
    --Helpers.addToChat("Config keys history cleared for device " .. device_code)
end

function Helpers.clearAllConfigKeysHistory()
    prev_config_keys_list = {}
    --Helpers.addToChat("All device config keys history cleared")
end

function Helpers.addConfigKeyToCurrent(device_code, config_key)
    if current_config_keys_list[device_code] and current_config_keys_list[device_code] ~= '' then
        Helpers.addConfigKeyToHistory(device_code, current_config_keys_list[device_code])
    end
    --Helpers.addToChat("Adding config key for device: " .. device_code .. " - Config Key: " .. config_key)
    current_config_keys_list[device_code] = config_key
end

function Helpers.displayConfigKeysCurrent(device_code)
    local config_key = current_config_keys_list[device_code]
    if not config_key or config_key == '' then
        Helpers.addToChat("No current config keys for device " .. device_code)
        return
    end
    Helpers.addToChat("Current Config Keys for device " .. device_code .. ": ".. config_key .. ".")
end

function Helpers.getPreviousConfigKeyFromHistory(device_code)
    local prev_config_key = Helpers.popLastConfigKeyFromHistory(device_code)
    if not prev_config_key then
        --Helpers.addToChat("No previous config key to load for device " .. device_code)
        return
    end
    current_config_keys_list[device_code] = nil -- Clear current config key before loading previous
    --Helpers.addToChat("Loaded previous config key '" .. prev_config_key .. "' to current for device " .. device_code)
    return prev_config_key
end

function Helpers.clearConfigKeysCurrent(device_code)
    current_config_keys_list[device_code] = nil
    Helpers.addToChat("Current config keys cleared for device " .. device_code .. ".")
end

function Helpers.clearAllConfigKeysCurrent() -- todo verify if this is needed
    current_config_keys_list = {}
    --Helpers.addToChat("All current device config keys cleared")
end

function Helpers.addAliasesListToCurrent(device_code, aliases_list)
    --Helpers.addToChat("Adding aliases list for device: " .. device_code)
    current_aliases_list[device_code] = aliases_list
end

function Helpers.displayAliasesListCurrent(device_code)
    local list = current_aliases_list[device_code]
    if not list or #list == 0 then
        Helpers.addToChat("No current aliases list for device " .. device_code)
        return
    end
    Helpers.addToChat("Current aliases list for device " .. device_code .. ":")
    for _, alias_item in ipairs(list) do
        Helpers.addToChat(alias_item.key .. ": " .. alias_item.value)
    end
end

function Helpers.clearAliasesListCurrent(device_code) -- todo verify if this is needed
    current_aliases_list[device_code] = {}
    --Helpers.addToChat("Current aliases list cleared for device " .. device_code)
end

function Helpers.clearAllAliasesListCurrent() -- todo verify if this is needed
    current_aliases_list = {}
    --Helpers.addToChat("All device aliases list cleared")
end

function Helpers.getCurrentActiveDevices()
    return current_active_devices
end

function Helpers.clearCurrentActiveDevices()
    current_active_devices = {}
    --Helpers.addToChat("All current active devices cleared")
end

function Helpers.addCurrentActiveDevice(device_code)
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    if settings.devices[device_code].options.box_disabled == false and not current_active_devices[device_code] then
        current_active_devices[device_code] = true
        --Helpers.addToChat("Added device " .. device_code .. " to current active devices.")
        devices_display_boxes[device_code].active = true
        devices_display_boxes[device_code].box:text(nil)
    end
end

function Helpers.removeCurrentActiveDevice(device_code)
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    if settings.devices[device_code].options.box_disabled == false and current_active_devices[device_code] then
        current_active_devices[device_code] = nil
        --Helpers.addToChat("Removed device " .. device_code .. " from current active devices.")
        devices_display_boxes[device_code].active = false
        devices_display_boxes[device_code].box:text(nil)
        devices_display_boxes[device_code].box:hide()
    end
end

function Helpers.setCurrentActiveDeviceText(device_code, config_keys)
    if settings.devices[device_code].options.box_disabled == true then
        return
    end
    if not device_code or device_code == '' or not devices_mapping[device_code] then
        Helpers.addToChat("No device code provided. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    if devices_display_boxes[device_code] and devices_display_boxes[device_code].box then
        local lines = {}
        table.insert(lines, '['..string.format('\\cs(0,0,220)%s\\cr', _addon.name).."] [" .. string.format('\\cs(0,0,220)%s\\cr', device_code) .. "] [" .. string.format('\\cs(0,0,220)%s\\cr', config_keys) .. "]")
        local list = current_aliases_list[device_code]
        if not list or #list == 0 then
            table.insert(lines, string.format('\\cs(255,0,0)%s\\cr', "No current aliases list."))
        else
            for _, alias_item in ipairs(list) do
                if alias_item.value == nil or alias_item.value == '' then
                    table.insert(lines, string.format('\\cs(255,0,0)%s\\cr', alias_item.key) .. ": "..string.format('\\cs(128,128,128)%s\\cr', "No value assigned"))
                else
                    table.insert(lines, string.format('\\cs(0,255,0)%s\\cr', alias_item.key) .. ": " .. alias_item.value)
                end
            end
        end
        devices_display_boxes[device_code].box:text(table.concat(lines, '\n'))
    end
end

return Helpers