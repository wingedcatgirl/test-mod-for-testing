TESTMOD4TESTING = TESTMOD4TESTING or {}

---Debug messages
---@param message string Message to send
---@param level? string 
---|"'FATAL'" # Something has gone horribly wrong and crashes are likely
---|"'ERROR'" # Something has gone horribly wrong, but crashes aren't likely (yet)
---|"'WARN '" # Something has gone wrong, but the program can handle it (e.g. call to a deprecated function)
---|"'INFO '" # Information even a casual player might want if they added DebugPlus
---|"'DEBUG'" # Debugging info most people don't need (default value)
---|"'TRACE'" # Potential debugging info even we don't (yet) need
TESTMOD4TESTING.say = function (message, level)
    level = level or "DEBUG"
    while #level < 5 do
        level = level .. " "
    end
    sendMessageToConsole(level, "Test Mod (For Testing)", message)
end
local say = TESTMOD4TESTING.say

--[[
SMODS.current_mod.calculate = function (self, context)

end
--]]

SMODS.current_mod.optional_features = {
    object_weights = true
}

TESTMOD4TESTING.event = function(func, args)
    args = args or {}
    args.func = args.func or func
    G.E_MANAGER:add_event(Event(args))
end

assert(SMODS.load_file("crash_webhooks.lua"))()

SMODS.Back{
    key = "Test",
    loc_txt = {
        name = "Test deck",
        text = {
            "For testing",
            "{C:inactive}(Immortal, plus whatever)",
        }
    },
    calculate = function (self, back, context)
        if context.stay_flipped and context.from_area == G.play and context.to_area == G.discard then
            return {
                modify = {
                    to_area = G.deck
                }
            }
        end

        if context.game_over then
            if G.GAME.round_resets.ante > 1 then
                ease_ante(-math.floor(G.GAME.round_resets.ante/2))
            end
            return {
                saved = "Nope!"
            }
        end
    end,
    config = {
        hand_size = 8
    },
    apply = function (self, back)
        G.GAME.starting_params.discards = G.GAME.starting_params.discards + 100
        G.GAME.starting_params.hands = G.GAME.starting_params.hands + 100
        TESTMOD4TESTING.event(function ()
            for i=1,5 do
                SMODS.add_card{
                    set = "Food"
                }
            end
            return true
        end, {blockable = false, blocking = false})
    end
}

SMODS.Back{
    key = "crashonpurpose",
    loc_txt = {
        name = "Crashing Deck",
        text = {
            "Deck that crashes the",
            "game when you start it"
        }
    },
    apply = function (self, back)
        error("Yeah, lemme just check if I'm playing the deck that crashes the game when you start it - aw, fuck.")
    end
}

--[[
SMODS.Joker{
    key = "testleg",
    loc_txt = {
        name = "Test Legend",
        text = {
            "It's legendary! :D"
        }
    },
    rarity = 4
}

SMODS.Stake{
    key = "teststake",
    applied_stakes = {
        "stake_gold"
    },
    prefix_config = {
        applied_stakes = false
    },
    loc_txt = {
        name = "Test Stake",
        text = {
            "It's above Gold",
            "(That's it, that's all it does)"
        },
        sticker = {
            name = "Test Sticker",
            text = {
                "Won with this Joker",
                "on Test Stake for Testing"
            }
        }
    }
}
--]]

SMODS.Tag{
    key = "monitoring",
    loc_txt = {
        name = "Monitoring Tag",
        text = {
            "When Tag:apply_to_run()",
            "is called, prints a debug",
            "message with the context",
        }
    },
    in_pool = function (self, args)
        return false
    end,
    loc_vars = function (self, info_queue, tag)

    end,
    apply = function (self, tag, context)
        if context then say(context.type); return end
    end
}

SMODS.Joker{
    key = "smissmas",
    config = {
        extra = {
            mult = 6
        }
    },
    loc_txt = {
        name = "Smissmas Joker",
        text = {
            "+#1# Mult (lie)"
        }
    },
    loc_vars = function (self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult
            }
        }
    end,
    in_pool = function (self, args)
        return false
    end
}

if next(SMODS.find_mod("FusionJokers")) then
    FusionJokers.fusions:register_fusion{
        jokers = {
            { name = "j_red_card", merge_stat = "mult" },
            { name = "j_green_joker", merge_stat = "mult" },
        },
        result_joker = "j_test_smissmas",
        merged_stat = "mult",
        cost = 7,
    }
end

function TESTMOD4TESTING.export_fucking_everything(mod_id, filter, overwrite) --function(card) return card.children.center.atlas.px ~= 71 or card.children.center.atlas.py ~= 95 or not not next(card.config.center.display_size or {}) end
    if not SMODS.card_to_image then
        sendErrorMessage("Too early, exporting isn't invented yet!", "Test Mod (For Testing)")
        return
    end
    if (G.STAGE ~= G.STAGES.RUN and G.STAGE ~= G.STAGES.SANDBOX) or G.SETTINGS.paused or not G.play then
        sendErrorMessage("Get into a game and unpaused to use this function!", "Test Mod (For Testing)")
        return
    end


    if not NFS.getInfo("exported card images", "directory") then
        NFS.createDirectory("exported card images")
    end

    for k, v in pairs(G.P_CENTERS) do
        if v.original_mod and (not mod_id or mod_id == v.original_mod.id) then
            G.E_MANAGER:add_event(Event {
                func = function()
                    local forbidden = "[/\\*\"<>:|?]"

                    local name = localize { type = "name_text", key = k, set = v.set }
                    local clean_name = name:gsub(forbidden, "X")
                    local modname = v.original_mod.name
                    local mod_folder_name = modname:gsub(forbidden, "X")
                    local mod_filename = mod_folder_name
                    local alt_modname = mod_folder_name .. " (altered names)"
                    if name == "ERROR" then
                        sendWarnMessage("Unable to localize " .. k)
                        clean_name = k
                        mod_folder_name = alt_modname
                    end
                    if name ~= clean_name or modname ~= mod_folder_name then
                        print("Sanitized " .. name .. " from " .. modname ..
                        " as '" .. clean_name .. " (" .. mod_filename .. ")")
                        mod_folder_name = alt_modname
                    end

                    if overwrite or not NFS.getInfo("exported card images/" .. mod_folder_name .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ").png") then
                        local card
                        if v.set == "Edition" then
                            card = SMODS.add_card {
                                key = "j_joker",
                                edition = k,
                                area = G.play
                            }
                        elseif v.set == "Enhancement" then
                            card = SMODS.add_card {
                                rank = "Ace",
                                suit = "Spades",
                                enhancement = k,
                                area = G.play
                            }
                        else
                            card = SMODS.add_card {
                                key = k,
                                area = G.play
                            }
                        end
                        local skip

                        if type(filter) == "function" then
                            skip = not filter(card)
                        end

                        if clean_name:find("#%d+#") then
                            local succ, vars = pcall(v.loc_vars, v, {}, card)
                            if succ then
                                for kk, vv in pairs(vars) do
                                    if type(kk) == "number" then
                                        clean_name = clean_name:gsub("#" .. tostring(kk) .. "#", tostring(vv))
                                    end
                                end

                                if NFS.getInfo("exported card images/" .. mod_folder_name .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ").png") and not overwrite then skip = true end
                            else
                                sendWarnMessage("Unable to get vars for " .. clean_name .. " from " .. mod_folder_name,
                                    "Test Mod (For Testing)")
                                mod_folder_name = alt_modname
                            end
                        end

                        if not skip then
                            if not NFS.getInfo("exported card images/" .. mod_folder_name, "directory") then
                                NFS.createDirectory("exported card images/" .. mod_folder_name)
                            end

                            if not NFS.getInfo("exported card images/" .. mod_folder_name .. "/" .. (v.set), "directory") then
                                NFS.createDirectory("exported card images/" .. mod_folder_name .. "/" .. (v.set))
                            end
                            local succ, res = pcall(SMODS.card_to_image, card, 1,
                                "exported card images/" ..
                                mod_folder_name .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ")")
                            if not succ then sendWarnMessage(res or "Unknown error", "Test Mod (For Testing)") end
                        end

                        SMODS.destroy_cards(card, {
                            immediate = true, skip_calc = true, silent = true, bypass_eternal = true
                        })
                    end
                    return true
                end
            })
        end
    end

    G.E_MANAGER:add_event(Event{
        func = function ()
            print"Done!"
            return true
        end
    })
end
