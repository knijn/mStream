local mode = settings.get("mStream.defaultMode","auto")
local modes = {"auto","tts","music"}
local channel = settings.get("mStream.channel")
local station = settings.get("mStream.station","An mStream Station")
local volume = settings.get("mStream.volume",1)
local id = os.getComputerID()
local protocol = "CCSMB-5"
local songDir = {"/songs/"}

local modem = peripheral.find("modem") or error("A modem must be attached")
local speaker = peripheral.find("speaker") or error("A speaker must be attached")
local title = "Nothing is playing right now"
local currentFile = ""
local buffer

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()


local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local unescape = function(url)
  return url:gsub("%%(%x%x)", hex_to_char)
end

local function playSong(file)
  currentFile = file
  title = fs.getName(unescape(file)):sub(1, -7)
  for chunk in io.lines(file, 16 * 1024) do
    local buffer = decoder(chunk)
    local packet = {buffer = buffer, id = id, station = station, title = title, protocol = protocol}
      modem.transmit(channel,channel,packet)

      while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
        sleep(0)
      end
  end
end

local function draw()
  while true do
    local xSize, ySize = term.getSize()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.write("mStream: " .. station .. "  |  " .. channel)
    term.setCursorPos(1,ySize - 1)
    term.write("Now Playing")
    term.setCursorPos(1,ySize)
    term.write(title)
    sleep(0.2)
  end
end

local function modeHandler()
  while true do
    if mode == "auto" then
      for i,folder in pairs(songDir) do
        for i,file in pairs(fs.list(folder)) do
          playSong(folder .. file)
        end
      end
    end
  end
end

local function keyHandler()
  while true do
    local event, key, is_held = os.pullEvent("key")
    if key == keys.three then
      mode = "music"
    elseif key == keys.two then
      mode = "tts"
    elseif key == keys.one then
      mode = "auto"
    end
  end
end


while true do
  parallel.waitForAny(draw,keyHandler,modeHandler)
end
