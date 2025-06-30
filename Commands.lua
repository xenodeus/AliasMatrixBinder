local addonCommands = {}

function addonCommands.Help() -- Show help message
    Helpers.addToChat("Available commands:")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("help"):color(220)..": Show this help message")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("list"):color(220)..": List available devices")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("setkeyshortcut"):color(220).." "..("<key_code>"):color(167)..": Set keyboard shortcut key code (8-254)")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("show"):color(220)..": Show current active devices aliases")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("hide"):color(220)..": Hide current active devices aliases")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("toggle"):color(220)..": Toggle visibility of current active devices aliases")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("saveboxes"):color(220)..": Save positions of current active devices aliases boxes")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("disablebox"):color(220).." "..("<device_code>"):color(167)..": Disable display box for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("repl"):color(220)..": Show available replacements")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("setonlogin"):color(220).." "..("<device_code>"):color(167)..": Reset use_on_login for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("setonlogin"):color(220).." "..("<device_code>"):color(167).." "..("<config_keys>"):color(167)..": Set use_on_login for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("setonjobchange"):color(220).." "..("<device_code>"):color(167)..": Reset use_on_job_change for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("setonjobchange"):color(220).." "..("<device_code>"):color(167).." "..("<config_keys>"):color(167)..": Set use_on_job_change for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("history"):color(220).." "..("<device_code>"):color(167)..": Show previous config keys for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("current"):color(220).." "..("<device_code>"):color(167)..": Show current aliases for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("prev"):color(220).." "..("<device_code>"):color(167)..": Use the previous config key for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("reset"):color(220)..": Reset aliases for all devices to defaults")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("reset"):color(220).." "..("<device_code>"):color(167)..": Reset aliases for the specified device to defaults")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("use"):color(220).." "..("<device_code>"):color(167)..": Load default aliases for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("use"):color(220).." "..("<device_code>"):color(167).." "..("<config_keys>"):color(167)..": Load specific aliases for the specified device")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("clean"):color(220).." "..("<device_code>"):color(167)..": Load default aliases for the specified device and clear history")
    Helpers.addToChat(" - "..(_addon.shortname):color(220).." "..("clean"):color(220).." "..("<device_code>"):color(167).." "..("<config_keys>"):color(167)..": Load specific aliases for the specified device and clear history")
    Helpers.addToChat(("<config_keys>"):color(167).." can be a combination of device-specific keys, separated by '+'.")
    Helpers.addToChat(("<config_keys>"):color(167).." can contain placeholders like {player_name} (See '"..(_addon.shortname):color(220).." "..("repl"):color(220).."').")
    Helpers.addToChat("Example: "..(_addon.shortname):color(220).." "..("use"):color(220).." "..("sdxl"):color(167).." "..("default+switches+config"):color(167))
end

function addonCommands.List() -- List available devices
    Helpers.addToChat("Available devices:")
    Helpers.listTable(devices_mapping)
end

function addonCommands.History(device_code) -- Show previous config keys for the specified device
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    Helpers.displayConfigKeysHistory(device_code)
end

function addonCommands.Current(device_code) -- Show current aliases for the specified device
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    Helpers.displayConfigKeysCurrent(device_code)
    Helpers.displayAliasesListCurrent(device_code)
end

function addonCommands.Prev(device_code) -- Use the previous config key for the specified device
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    local prev_config_key = Helpers.getPreviousConfigKeyFromHistory(device_code)
    if not prev_config_key or prev_config_key == '' then
        Helpers.addToChat("No previous config key found for device '" .. device_code .. "'.")
        return
    end
    addonCommands.Use(device_code, prev_config_key)
end

function addonCommands.Reset(device_code) -- Reset aliases for the specified device to defaults
    if device_code == nil or device_code == '' then
        Helpers.addToChat("Resetting aliases for all devices to defaults.")
        Helpers.clearAllConfigKeysHistory()
        return
    end
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    local default_device_aliases = Helpers.load_default_device_aliases(device_code)
    if not Helpers.validateTableData(default_device_aliases) then
        Helpers.addToChat("Failed to load defaults aliases for device '" .. device_code .. "'.")
        return
    end
    Helpers.clearConfigKeysHistory(device_code)
    Helpers.setAliases(default_device_aliases)
    Helpers.removeCurrentActiveDevice(device_code) -- Remove the device from current active devices
    Helpers.addToChat("Aliases for device '" .. device_code .. "' have been reset to defaults.")
end

function addonCommands.Use(device_code, config_keys) -- Use a specific config key for the specified device
    if not devices_mapping[device_code] then -- Check if the device code is valid
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end

    local default_device_aliases = Helpers.load_default_device_aliases(device_code) -- Load default aliases for the device
    if not Helpers.validateTableData(default_device_aliases) then -- Check if the default aliases are valid
        Helpers.addToChat("Failed to load defaults aliases for device '" .. device_code .. "'.")
        return
    end

    local aliases = {}
    for alias_key, alias_value in pairs(default_device_aliases) do -- Iterate over default aliases
        aliases[alias_key] = alias_value
    end

    local config_keys = Helpers.replaceKeysInString(config_keys) -- Replace keys in the config keys string
    Helpers.addConfigKeyToCurrent(device_code, config_keys) -- Add the config keys to the current device's history
    
    local config_key_list = config_keys:split('+') -- Split the config keys by '+'
    -- Load aliases for each config key
    for _, config_key in ipairs(config_key_list) do -- Iterate over config keys
        for alias_key, alias_value in pairs(Helpers.load_all_aliases(device_code, config_key)) do -- Load all aliases for the config key
            aliases[alias_key] = alias_value
        end
    end

    Helpers.setAliases(device_code, aliases) -- Set the aliases for the device
    Helpers.addCurrentActiveDevice(device_code) -- Automatically add device to current active devices
    Helpers.setCurrentActiveDeviceText(device_code, config_keys) -- Update display text for the device

    --Helpers.addToChat("["..(devices_mapping[device_code]):color(220).."] [" .. (config_keys):color(220) .. "] ["..('LOADED'):color(158).."]")
    Helpers.addToChat("["..(device_code):color(220).."] [" .. (config_keys):color(220) .. "] ["..('LOADED'):color(158).."]")
    --Helpers.addToChat("Defaults for device '" .. device_code .. "' have been loaded successfully.")
end

function addonCommands.Clean(device_code, config_keys) -- Use config with Cleaned history
    Helpers.clearConfigKeysHistory(device_code)
    Helpers.clearConfigKeysCurrent(device_code)
    addonCommands.Use(device_code, config_keys, true)
end

function addonCommands.Repl()
    Helpers.displayAvailableReplacements()
    Helpers.addToChat("You can use those replacements in config keys and aliases.")
    Helpers.addToChat("Example: "..(_addon.shortname):color(220).." "..("use"):color(220).." "..("sdxl"):color(167).." "..("default+switches+spec_{player_name}"):color(167))
    Helpers.addToChat("You can also setup custom replacements in the data/custom_replacements.lua file.")
    Helpers.addToChat('Example: return {["myCharacterName"] = "My Character Name"}')
    Helpers.addToChat('Example: ["{myJob}"] = windower.ffxi.get_player().main_job and windower.ffxi.get_player().main_job:upper() or ""')
end

function addonCommands.SetOnLogin(device_code, config_keys) -- Set use_on_login for the specified device
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    settings.devices[device_code].options.use_on_login = config_keys or ''
    config.save(settings)
    Helpers.addToChat("Set use_on_login for device '" .. device_code .. "' to: " .. settings.devices[device_code].options.use_on_login .. ".")
end

function addonCommands.SetOnJobChange(device_code, config_keys) -- Set use_on_job_change for the specified device
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    settings.devices[device_code].options.use_on_job_change = config_keys or ''
    config.save(settings)
    Helpers.addToChat("Set use_on_job_change for device '" .. device_code .. "' to: " .. settings.devices[device_code].options.use_on_job_change .. ".")
end

function addonCommands.Show()
    for _, item in ipairs(Helpers.sort_table_by_key_numbers(Helpers.getCurrentActiveDevices())) do
        if devices_display_boxes[item.key] and devices_display_boxes[item.key].active then
            devices_display_boxes[item.key].box:show()
        end
    end
end

function addonCommands.Hide()
    for _, item in ipairs(Helpers.sort_table_by_key_numbers(Helpers.getCurrentActiveDevices())) do
        if devices_display_boxes[item.key] and devices_display_boxes[item.key].active then
            devices_display_boxes[item.key].box:hide()
        end
    end
end

function addonCommands.Toggle()
    for _, item in ipairs(Helpers.sort_table_by_key_numbers(Helpers.getCurrentActiveDevices())) do
        if devices_display_boxes[item.key] and devices_display_boxes[item.key].active then
            if texts.visible(devices_display_boxes[item.key].box) then
                devices_display_boxes[item.key].box:hide()
            else
                devices_display_boxes[item.key].box:show()
            end
        end
    end
end

function addonCommands.SaveBoxes()
    for _, item in ipairs(Helpers.sort_table_by_key_numbers(Helpers.getCurrentActiveDevices())) do
        if devices_display_boxes[item.key] and devices_display_boxes[item.key].active then
            local box = devices_display_boxes[item.key].box
            local x, y = box:pos()
            settings.devices[item.key].box.pos.x = x
            settings.devices[item.key].box.pos.y = y
            config.save(settings)
            Helpers.addToChat("Saved position for device '" .. item.key .. "': (" .. x .. ", " .. y .. ")")
        end
    end
end

function addonCommands.DisableBox(device_code)
    if not devices_mapping[device_code] then
        Helpers.addToChat("Invalid device code. Use '".._addon.shortname.." list' to see available devices.")
        return
    end
    settings.devices[device_code].options.box_disabled = true
    config.save(settings)
    Helpers.addToChat("Display box for device '" .. device_code .. "' has been disabled in settings.")
    if devices_display_boxes[device_code] then
        devices_display_boxes[device_code].active = false
        devices_display_boxes[device_code].box:hide()
    end
end

function addonCommands.SetKeyboardShortcut(key_code)
    key_code = tonumber(key_code)
    if key_code and key_code >= 8 and key_code <= 254 then
        settings.options.keyboard_shortcut = key_code
        config.save(settings)
        Helpers.addToChat("Keyboard shortcut set to: " .. key_code)
    else
        Helpers.addToChat("Invalid keyboard shortcut key code. Please provide a number between 8 and 254.")
    end
end

return addonCommands