VOIDTERM = VOIDTERM or {}
VOIDTERM.Beep = {}
local toneCache = {}
local function GenerateTone(frequency, duration, volume)
    frequency = math.Round(frequency / 50) * 50
    duration = math.Round(duration / 50) * 50
    local cacheKey = frequency .. "_" .. duration
    if toneCache[cacheKey] then return toneCache[cacheKey] end
    frequency = frequency or 800
    duration = duration or 200
    volume = volume or 0.5
    local sampleRate = 22050
    local samples = math.floor(sampleRate * duration / 1000)
    local data = {}
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local sample = math.sin(2 * math.pi * frequency * t) * volume
        local fadeLen = math.min(samples * 0.1, 500)
        if i < fadeLen then
            sample = sample * (i / fadeLen)
        elseif i > samples - fadeLen then
            sample = sample * ((samples - i) / fadeLen)
        end
        local byte = math.floor((sample + 1) * 127.5)
        byte = math.Clamp(byte, 0, 255)
        table.insert(data, string.char(byte))
    end
    local dataStr = table.concat(data)
    local dataLen = #dataStr
    local fileLen = dataLen + 36
    local wav = "RIFF"
    wav = wav .. string.char(
        bit.band(fileLen, 0xFF),
        bit.band(bit.rshift(fileLen, 8), 0xFF),
        bit.band(bit.rshift(fileLen, 16), 0xFF),
        bit.band(bit.rshift(fileLen, 24), 0xFF)
    )
    wav = wav .. "WAVE"
    wav = wav .. "fmt "
    wav = wav .. string.char(16, 0, 0, 0)
    wav = wav .. string.char(1, 0)
    wav = wav .. string.char(1, 0)
    wav = wav .. string.char(
        bit.band(sampleRate, 0xFF),
        bit.band(bit.rshift(sampleRate, 8), 0xFF),
        bit.band(bit.rshift(sampleRate, 16), 0xFF),
        bit.band(bit.rshift(sampleRate, 24), 0xFF)
    )
    wav = wav .. string.char(
        bit.band(sampleRate, 0xFF),
        bit.band(bit.rshift(sampleRate, 8), 0xFF),
        bit.band(bit.rshift(sampleRate, 16), 0xFF),
        bit.band(bit.rshift(sampleRate, 24), 0xFF)
    )
    wav = wav .. string.char(1, 0)
    wav = wav .. string.char(8, 0)
    wav = wav .. "data"
    wav = wav .. string.char(
        bit.band(dataLen, 0xFF),
        bit.band(bit.rshift(dataLen, 8), 0xFF),
        bit.band(bit.rshift(dataLen, 16), 0xFF),
        bit.band(bit.rshift(dataLen, 24), 0xFF)
    )
    wav = wav .. dataStr
    toneCache[cacheKey] = wav
    return wav
end
function VOIDTERM.Beep.Play(frequency, duration)
    frequency = math.Round((frequency or 800) / 50) * 50
    duration = math.Round((duration or 200) / 50) * 50
    local filename = "voidterm_beep_" .. frequency .. "_" .. duration .. ".wav"
    if not file.Exists(filename, "DATA") then
        local wav = GenerateTone(frequency, duration, 0.6)
        file.Write(filename, wav)
    end
    sound.PlayFile("data/" .. filename, "noblock", function(station)
        if IsValid(station) then
            station:SetVolume(0.7)
            station:Play()
        end
    end)
end
function VOIDTERM.Beep.PlaySequence(notes, delay)
    delay = delay or 0.2
    for i, note in ipairs(notes) do
        timer.Simple((i-1) * delay, function()
            VOIDTERM.Beep.Play(note.freq or 800, note.dur or 100)
        end)
    end
end
