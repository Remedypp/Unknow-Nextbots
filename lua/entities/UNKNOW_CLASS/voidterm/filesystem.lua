VOIDTERM = VOIDTERM or {}
VOIDTERM.FileSystem = {}
local BASE_DIR = "voidterm"
function VOIDTERM.FileSystem.Init()
    if not file.Exists(BASE_DIR, "DATA") then
        file.CreateDir(BASE_DIR)
    end
    if file.IsDir(BASE_DIR, "DATA") then
    else
    end
    VOIDTERM.FileSystem.Test()
    if VOIDTERM.FileSystem.InstallDefaults then
        VOIDTERM.FileSystem.InstallDefaults()
    end
end
function VOIDTERM.FileSystem.InstallDefaults()
    if not VOIDTERM.Defaults then return end
    for filename, content in pairs(VOIDTERM.Defaults) do
        local realPath = BASE_DIR .. "/" .. filename .. ".txt"
        VOIDTERM.FileSystem.Save(filename, content)
    end
end
function VOIDTERM.FileSystem.Test()
    local rootPath = "voidterm_root_test.txt"
    file.Write(rootPath, "ROOT TEST")
    if file.Exists(rootPath, "DATA") then
        file.Delete(rootPath)
    else
    end
    if not file.Exists(BASE_DIR, "DATA") then
        file.CreateDir(BASE_DIR)
    end
    if file.IsDir(BASE_DIR, "DATA") then
        local testPath = BASE_DIR .. "/test_write.txt"
        file.Write(testPath, "SUBFOLDER TEST")
        if file.Exists(testPath, "DATA") then
            file.Delete(testPath)
        else
        end
    else
    end
end
function VOIDTERM.FileSystem.Save(filename, content)
    if not filename or filename == "" then return false, "Invalid filename" end
    filename = string.GetFileFromFilename(filename)
    if not file.IsDir(BASE_DIR, "DATA") then
        file.CreateDir(BASE_DIR)
    end
    local realPath = BASE_DIR .. "/" .. filename .. ".txt"
    file.Write(realPath, content)
    if file.Exists(realPath, "DATA") then
        return true
    else
        local f = file.Open(path, "w", "DATA")
        if f then
            f:Write(content)
            f:Close()
            if file.Exists(path, "DATA") then
                return true
            end
        end
        return false, "Write failed"
    end
end
function VOIDTERM.FileSystem.Load(filename)
    if not filename or filename == "" then return nil, "Invalid filename" end
    if not string.find(filename, "%.") then filename = filename .. ".void" end
    local realPath = BASE_DIR .. "/" .. filename .. ".txt"
    if not file.Exists(realPath, "DATA") then
        return nil, "File not found"
    end
    return file.Read(realPath, "DATA")
end
function VOIDTERM.FileSystem.List()
    local files, _ = file.Find(BASE_DIR .. "/*.txt", "DATA")
    local cleanFiles = {}
    for _, f in ipairs(files or {}) do
        local cleanName = string.sub(f, 1, -5)
        table.insert(cleanFiles, cleanName)
    end
    return cleanFiles
end
function VOIDTERM.FileSystem.Delete(filename)
    if not filename or filename == "" then return false, "Invalid filename" end
    local realPath = BASE_DIR .. "/" .. filename .. ".txt"
    if not file.Exists(realPath, "DATA") then return false, "File not found" end
    file.Delete(realPath)
    return true
end
VOIDTERM.FileSystem.Init()
