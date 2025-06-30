--[[
Copyright © 2025, Xenodeus
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of AliasMatrixBinder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Xenodeus BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]--

_addon.name = "AliasMatrixBinder"
_addon.author = "Xenodeus"
_addon.version = "1.0.0"
_addon.commands = {"AliasMatrixBinder", "ambinder"}
_addon.shortname = "ambinder"

require('logger')
--require('matrices')
--require('tables')
--require('functions')
--require('strings')
--require('chat')
config = require('config')
files = require('files')
texts = require('texts')

Heartbeat = 0
job_change_timestamp = 0

-- Load the helpers module
Helpers = require('Helpers')
-- Load the devices mapping module
devices_mapping = require('DevicesMapping')
-- Load the addon commands module
addonCommands = require('Commands')

defaults = {}
defaults.options = {
	job_files_create_if_not_exists = false,
    user_files_create_if_not_exists = false,
    keyboard_shortcut = 207 -- END Key Code
}
defaults.devices = {}
devices_display_boxes = {}
default_pos_x = 100
default_pos_y = 100
for _, item in ipairs(Helpers.sort_table_by_key_numbers(devices_mapping)) do
    defaults.devices[item.key] = {
        box = {
            pos = {x = default_pos_x, y = default_pos_y},
            padding = 8,
            text = {
                font = 'Consolas',
                size = 10,
                color = {150, 150, 150},
                stroke = {width = 2, alpha = 255}
            },
            bg = {
                alpha=150,
            },
            flags = {}
        }, 
        options = {
            box_disabled = false,
            use_on_login = '',
            use_on_job_change = '',
        }
    }
    default_pos_x = default_pos_x + 10
    default_pos_y = default_pos_y + 10
end

settings = config.load(defaults)
for _, item in ipairs(Helpers.sort_table_by_key_numbers(settings.devices)) do
    local device_code = item.key
    local device_settings = item.value
    if device_settings.options.box_disabled == false then
        -- Create the display box for each device
        devices_display_boxes[device_code] = {
            box = texts.new(device_settings.box),
            active = false,
        }
        devices_display_boxes[device_code].box:hide()
        devices_display_boxes[device_code].box:pos(device_settings.box.pos.x, device_settings.box.pos.y)
    end
end

local keyboard_shortcut = settings.options.keyboard_shortcut or 207

windower.register_event('addon command',function (...)
    local commands = {...}
    for x=1,#commands do commands[x] = windower.convert_auto_trans(commands[x]):lower() end
    
    if commands[1] == 'help' then
        addonCommands.Help()
        return
    elseif commands[1] == 'list' then
        addonCommands.List()
        return
    elseif commands[1] == 'show' then
        addonCommands.Show()
        return
    elseif commands[1] == 'hide' then
        addonCommands.Hide()
        return
    elseif commands[1] == 'toggle' then
        addonCommands.Toggle()
        return
    elseif commands[1] == 'saveboxes' then
        addonCommands.SaveBoxes()
        return
    elseif commands[1] == 'disablebox' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to disable the box.")
            return
        end
        addonCommands.DisableBox(commands[2]:lower())
        return
    elseif commands[1] == 'history' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.History(commands[2]:lower())
        return
    elseif commands[1] == 'current' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.Current(commands[2]:lower())
        return
    elseif commands[1] == 'prev' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.Prev(commands[2]:lower())
        return
    elseif commands[1] == 'reset' then
        addonCommands.Reset(commands[2]~=nil and commands[2]:lower() or nil)
        return
    elseif commands[1] == 'use' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.Use(commands[2]:lower(), commands[3] or 'default')
        return
    elseif commands[1] == 'clean' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.Clean(commands[2]:lower(), commands[3] or 'default')
        return
    elseif commands[1] == 'repl' then
        addonCommands.Repl()
        return
    elseif commands[1] == 'setonlogin' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.SetOnLogin(commands[2]:lower(), table.concat(commands, ' ', 3))
        return
    elseif commands[1] == 'setonjobchange' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a device code to set.")
            return
        end
        addonCommands.SetOnJobChange(commands[2]:lower(), table.concat(commands, ' ', 3))
        return
    elseif commands[1] == 'setkeyshortcut' then
        if not commands[2] or commands[2] == '' then
            Helpers.addToChat("Please specify a keyboard shortcut key code.")
            return
        end
        addonCommands.SetKeyboardShortcut(commands[2])
        return
    else
        Helpers.addToChat("Unknown command: " .. commands[1])
        addonCommands.Help()
    end
end)

windower.register_event('keyboard', function(key, pressed)
    if key == keyboard_shortcut then
        if windower.ffxi.get_info().logged_in then
            if pressed then
                addonCommands.Show()
            else
                addonCommands.Hide()
            end
        end
    end
    -- Debugging output for key presses
    -- Uncomment the line below to see key presses in the chat log
    --windower.add_to_chat(123, key..' :: '..string.format("Key: %X | Pressed: %s", key, tostring(pressed)))
end)

windower.register_event('login', function() -- This event is called when the player logs in
    --Wait 4 seconds for information to be loaded
	coroutine.schedule(function()
        -- Load the settings on login
        settings = config.load(defaults)
        -- Reset the addon commands and clear cached replacements
        addonCommands.Reset()
        Helpers.clearCachedReplacements()
        Helpers.clearCurrentActiveDevices()
        -- Apply the use_on_login settings for each device
        for _, device in pairs(Helpers.sort_table_by_key_numbers(settings.devices)) do
            if device.key and device.value and device.value.options and device.value.options.use_on_login and device.value.options.use_on_login ~= '' then
                addonCommands.Clean(device.key, device.value.options.use_on_login)
            end
        end
    end, 4)
end)
windower.register_event('load', function()
	--If already logged in, run initialize immediately and set the lockstyle
    if windower.ffxi.get_info().logged_in then
        -- Reset the addon commands and clear cached replacements
        addonCommands.Reset()
        Helpers.clearCachedReplacements()
        Helpers.clearCurrentActiveDevices()
		-- Apply the use_on_login settings for each device
        for _, device in pairs(Helpers.sort_table_by_key_numbers(settings.devices)) do
            if device.key and device.value and device.value.options and device.value.options.use_on_login and device.value.options.use_on_login ~= '' then
                addonCommands.Clean(device.key, device.value.options.use_on_login)
            end
        end
	end
end)

windower.register_event('job change',function() -- This event is called when the player's job changes
    -- Reset the heartbeat to ensure job change commands are executed after a delay
    job_change_timestamp = os.time() + 6
end)

windower.register_event('prerender', function() -- This event is called every frame before rendering
    -- Check if the heartbeat interval has passed
    -- This is used to execute the job change commands after a delay 
    if os.time() > Heartbeat then
		Heartbeat = os.time()
		if job_change_timestamp > 0 and os.time() >= job_change_timestamp then -- If the job change timestamp is reached
            -- Reset the job change timestamp
			job_change_timestamp = 0
            -- Reset the addon commands and clear cached replacements
            addonCommands.Reset()
            Helpers.clearCachedReplacements()
            Helpers.clearCurrentActiveDevices()

            -- Apply the use_on_job_change settings for each device
            for _, device in pairs(Helpers.sort_table_by_key_numbers(settings.devices)) do
                if device.key and device.value and device.value.options and device.value.options.use_on_job_change and device.value.options.use_on_job_change ~= '' then
                    addonCommands.Clean(device.key, device.value.options.use_on_job_change)
                end
            end
		end
	end
end)
