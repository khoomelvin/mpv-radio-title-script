--[[
  Get title for current song from external source
]]--

local settings = {
    radio_title_helper = "/usr/local/bin/radio_title_helper", -- Path to Radio title helper
    interval = 10, -- Renew every 10 seconds (default)
    radios = {"fip", "franceculture", "francemusique", "tsfjazz", "franceinter"}, -- enable script for these radios (keyword must be in stream url)
}

require 'mp.options'
read_options(settings, "radiotitle")
local msg = require 'mp.msg'
local utils = require 'mp.utils'

function get_song_name()
  local radio_url = mp.get_property('stream-open-filename')
  local has_failed = false -- We may not have title during ads, no need to display multiple error messages
  t = {}  
  t.args = {settings.radio_title_helper, radio_url}
  res = utils.subprocess(t)
  if res.status == 0 then
      has_failed = false
      return res.stdout
  elseif not has_failed then
      has_failed = true
      mp.msg.warn("Could not retrieve title")
  end
end

function change_title()
  local title = mp.get_property('media-title')
  local new_title = get_song_name()
  if new_title and title ~= new_title then 
    mp.set_property("file-local-options/force-media-title", new_title)
    msg.info("Now playing "..new_title)
  end
  mp.add_timeout(settings.interval, change_title)
end


function enable_script()
  local radio_url = mp.get_property('stream-open-filename')
  for index, radio in ipairs(settings.radios) do
      if string.find(radio_url, radio) then
        change_title()
      end
  end
end

-- Wait 5s for mpv to open stream
mp.add_timeout(5, enable_script)