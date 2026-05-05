local base = "https://raw.githubusercontent.com/Goofberg/McCCTweaked-SporeReconTurtle/main/SecurityTriggered"

local function download(url, path)
  local res = http.get(url)
  if not res then
    print("Failed:", url)
    return false
  end

  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then
    fs.makeDir(dir)
  end

  local file = fs.open(path, "w")
  file.write(res.readAll())
  file.close()
  res.close()

  print("Downloaded:", path)
  return true
end

local res = http.get(base .. "manifest.json")
if not res then error("Failed to fetch manifest") end

local manifest = textutils.unserializeJSON(res.readAll())
res.close()

for _, file in ipairs(manifest.files) do
  download(base .. file, file)
end

local this = shell.getRunningProgram()

local f = fs.open("cleanup.lua", "w")
f.write("sleep(0.5)\n")
f.write("if fs.exists('" .. this .. "') then fs.delete('" .. this .. "') end\n")
f.write("fs.delete('cleanup.lua')\n")
f.close()

shell.run("cleanup.lua")

print("Full repo installed!")
