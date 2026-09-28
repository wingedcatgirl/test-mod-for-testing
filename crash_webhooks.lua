-- Adapted from ivy real_niacat's code
TESTMOD4TESTING.say("Loading crash messages...", "TRACE")

local http = require("SMODS.https")
local json = require("json")

local gitfolder = SMODS.current_mod.path..".git/" --Change this if your git folder is in a weird place
local exclude_file_path = gitfolder.."info/exclude"
local exclude_entry = "*webhooks.txt"
local excluded = false
local gitfolderdata = NFS.getDirectoryItems(gitfolder)
if gitfolderdata and next(gitfolderdata) then
    for line in NFS.lines(exclude_file_path) do
        if line == exclude_entry then
            excluded = true
            break
        end
    end
    if not excluded then
        NFS.write(exclude_file_path, NFS.read(exclude_file_path).."\n"..exclude_entry)
        excluded = true
    end
else
    print".git folder isn't in the expected area, you're on your own."
end

local modder_names = {}
for i, v in ipairs(SMODS.current_mod.author) do
    modder_names[v] = true
end

local function send_that_webhook(msg, target)
    local data = {
        method = "POST",
        data = json.encode{content = msg},
        headers = {
            ["Content-Type"] = "application/json"
        }
    }
    if http then
        return http.request(target, data)
    else
        print("Oops! No HTTP! Don't worry, your good old buddy print has this covered:")
        print(msg)
        return
    end
end

function TESTMOD4TESTING.webhook_test(mod)
    mod = mod or "testmod"
    local msg = "Testing that webhook!"
    local webhook_list = TESTMOD4TESTING.read_hook_file(mod)
    if webhook_list then
        local crashcount_filename = mod .. "_crashes.txt"
        local crash_count = tonumber(love.filesystem.read(crashcount_filename) or 0)

        for url, datamsg in pairs(webhook_list) do
            print("Found: ", url, datamsg)
            print(send_that_webhook(msg, url))
        end
    end
end

--Don't edit this text here. To be clear.
local unedited_text = "After creating the webhook file, replace this text inside it with a return-separated list of webhook URLs.\nThey may (optionally) be followed by a pipe symbol | and a custom message.\nUse #modname# for the mod's name, and #crashcount# for the number of times crashed so far."

function TESTMOD4TESTING.creat_hook_file(modname)
    NFS.write(modname.."_webhooks.txt", unedited_text)
end

local default_msg = "Looks like #modname# crashed again! This makes #crashcount# times since we started tracking!"

function TESTMOD4TESTING.read_hook_file(modname)
    local data = NFS.read(modname.."_webhooks.txt")
    local all_webhooks = {}
    if data and data ~= unedited_text then
        for line in NFS.lines(modname.."_webhooks.txt") do
            local url, msg
            local parts = {}
            for part in string.gmatch(line, "[^|]+") do
                local realpart = part
                while realpart:sub(1,1):find("%s") do
                    realpart = realpart:sub(2)
                end
                while realpart:sub(#realpart):find("%s") do
                    realpart = realpart:sub(1, #realpart-1)
                end

                parts[#parts+1] = realpart
            end
            if #parts == 2 then
                url, msg = parts[1], parts[2]
            else
                url = line
                msg = default_msg
            end
            all_webhooks[url] = msg
        end
    else
        local errmsg = "Nope!" .. (data == unedited_text and " You gotta put the URLS in the file first!" or "")
        TESTMOD4TESTING.say(errmsg, "WARN ")
        return
    end
    return all_webhooks
end

local default_author = SMODS.current_mod.author[1]

function TESTMOD4TESTING.creat_all_hook_files(author)
    author = author or default_author

    for k,v in pairs(SMODS.Mods) do
        local is_for_me = false
        for _,modder in ipairs(v.author or {}) do
            if modder == author then
                is_for_me = true
                break
            end
        end

        if is_for_me and not NFS.read(k.."_webhooks.txt") then
            print("Creating webhook file for mod "..k)
            if not excluded then
                print"WARNING! Unable to find or create an entry in .git/info/exclude for these files!\nPlease ensure, by whichever means you have available, that you don't make them public by mistake."
            end
            TESTMOD4TESTING.creat_hook_file(k)
        end
    end
end

local loveerrorhandler = love.errorhandler
love.errorhandler = function (...)
    for k,v in pairs(SMODS.Mods) do
        local is_for_me = false
        for _,modder in ipairs(v.author or {}) do
            if modder_names[modder] then
                is_for_me = true
                break
            end
        end

        if v.can_load and is_for_me and love.filesystem.exists(k.."_webhooks.txt") then
            local webhook_list = TESTMOD4TESTING.read_hook_file(k)
            if webhook_list then
                local crashcount_filename = k.."_crashes.txt"
                local crash_count = tonumber(love.filesystem.read(crashcount_filename) or 0)
                crash_count = crash_count + 1
                love.filesystem.write(crashcount_filename, tostring(crash_count))

                for url,msg in pairs(webhook_list) do
                    msg = msg:gsub("#modname#", v.name):gsub("#crashcount#", crash_count)

                    send_that_webhook(msg, url)
                end
            end
        end
    end

    return loveerrorhandler(...)
end