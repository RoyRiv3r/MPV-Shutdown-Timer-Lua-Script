local options = require 'mp.options'

-- Define the shortcut key
local shutdown_key = "Ctrl+i"

-- Table to hold the different shutdown options, plus a cancel option
local shutdown_options = {
        -- {duration = 30, label = "30 seconds"}, test
    {duration = 30 * 60, label = "30 minutes"},
    {duration = 60 * 60, label = "1 hour"},
    {duration = 2 * 60 * 60, label = "2 hours"},
    {duration = 4 * 60 * 60, label = "4 hours"},
    {duration = nil, label = "end of video"}, -- nil duration for end of video
    {duration = -1, label = "cancel shutdown"} -- Special case for cancellation
}
local current_option_index = 0 -- Start with the first option

-- Timer for scheduled shutdown
local shutdown_timer = nil

-- Function to update the shutdown timer
function update_shutdown_timer(duration)
    -- Cancel any existing timer
    if shutdown_timer then
        shutdown_timer:kill()
        shutdown_timer = nil
    end

    -- Schedule a new timer if the duration is positive
    if duration and duration > 0 then
        shutdown_timer = mp.add_timeout(duration / mp.get_property_number("speed", 1), shutdown_system)
        mp.osd_message("System shutdown scheduled in " .. shutdown_options[current_option_index].label)
    elseif duration == nil then
        -- Schedule for end of video
        mp.osd_message("System shutdown scheduled for end of video")
    end
end

-- Function to cancel scheduled shutdown
function cancel_shutdown()
    if shutdown_timer then
        shutdown_timer:kill()
        shutdown_timer = nil
    end
    -- Check if the current option is 'end of video' and display a message accordingly
    if shutdown_options[current_option_index].duration == nil then
        mp.osd_message("End of video shutdown cancelled")
    else
        mp.osd_message("System shutdown cancelled")
    end
end

-- Function to shutdown the system
function shutdown_system()
    mp.osd_message("Shutting down system...")
    os.execute("shutdown /s /t 0")
        -- os.execute("sudo shutdown -h now")  -- For Linux/macOS
end

-- Bind the shortcut key to cycle through shutdown options
mp.add_key_binding(shutdown_key, "cycle_shutdown_option", function()
    current_option_index = (current_option_index % #shutdown_options) + 1
    local option = shutdown_options[current_option_index]

    if option.duration == -1 then
        cancel_shutdown()
    else
        update_shutdown_timer(option.duration)
    end
end)

-- Register the shutdown function to be called at the end of each file if that option is selected
mp.register_event("end-file", function()
    local option = shutdown_options[current_option_index]
    if option.duration == nil then
        shutdown_system()
    end
end)
