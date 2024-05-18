VERSION = "0.2.0"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local buffer = import("micro/buffer")

function misspellCommand()
    micro.CurPane():Save(false)
    runMisspell()
end


function init()
    if config.GetGlobalOption("misspell.EnableMisspell") == nil then
        config.RegisterGlobalOption("misspell", "EnableMisspell", true)
    end

    config.MakeCommand("misspell", misspellCommand, config.NoComplete)
end

function runMisspell()
    micro.CurPane().Buf:ClearMessages("misspell")
    shell.JobSpawn("misspell", {micro.CurPane().Buf.Path}, nil, nil, onExit, "%f:%l:%d+: %m")
    -- micro.InfoBar():Message("Running misspell ", micro.CurPane().Buf.Path)
    micro.Log("Running misspell ", micro.CurPane().Buf.Path)
end

function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

function basename(file)
    local name = string.gsub(file, "(.*/)(.*)", "%2")
    return name
end

function onSave(view)
    if config.GetGlobalOption("misspell.EnableMisspell") then
        runMisspell()
    else
        micro.CurPane():ClearMessages()
    end
end

function onExit(output, args)
    micro.Log("output: ", output)

    local lines = split(output, "\n")
    local errorformat = args[1]
    local regex = errorformat:gsub("%%f", "(..-)"):gsub("%%l", "(%d+)"):gsub("%%m", "(.+)")
    for _,line in ipairs(lines) do

        -- Trim whitespace
        line = line:match("^%s*(.+)%s*$")
        if string.find(line, regex) then
            local file, line, msg = string.match(line, regex)
            micro.Log("file: ", file)
            micro.Log("line: ", line)
            micro.Log("msg: ", msg)

            if basename(micro.CurPane().Buf.Path) == basename(file) then
                -- I don't know what this does, I saw this is done on LSP ¯\_(ツ)_/¯
                micro.CurPane().Buf:AddMessage(buffer.NewMessage("misspell", "", buffer.Loc(0, 10000000), buffer.Loc(0, 10000000), buffer.MTInfo))
                local mess = buffer.NewMessageAtLine("misspell", msg, tonumber(line), buffer.MTError)
                micro.CurPane().Buf:AddMessage(mess)
            end
        end
    end
end
