--SMODS.load_file("Challengecode.lua")()

local say = function (message)
    sendDebugMessage(message, "Test Mod (For Testing)")
end

TESTMOD4TESTING = TESTMOD4TESTING or {}

--[[
SMODS.current_mod.calculate = function (self, context)

end
--]]

TESTMOD4TESTING.event = function(func, args)
    args = args or {}
    args.func = args.func or func
    G.E_MANAGER:add_event(Event(args))
end

SMODS.Back{
    key = "Test",
    loc_txt = {
        name = "Test deck",
        text = {
            "For testing",
            "{C:inactive}(Immortal, 100 hands+discards)",
            "{C:inactive}(16 cards that stay in hand)",
            "{C:inactive}(plus whatever else you typed)"
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
            if not next(SMODS.find_mod("FishAndChips")) then return true end
            if not G.fac_fish_area then return false end
            local jokers_to_add = {
                "fish_fac_proto_noir",
                --"fish_fac_proto_lockpick",
                "j_splash",
                "j_chicot",
            }

            for i,v in ipairs(jokers_to_add) do
                if G.P_CENTERS[v] then
                    local card = SMODS.add_card{key = v}
                    card.ability.extra_slots_used = -1
                end
            end

            TESTMOD4TESTING.event(function ()
                local cards_to_shred = {}
                for i,v in ipairs(G.playing_cards) do
                    cards_to_shred[#cards_to_shred+1] = v
                    if #cards_to_shred > 36 then
                        table.remove(cards_to_shred, math.random(#cards_to_shred))
                    end
                end
                SMODS.destroy_cards(cards_to_shred, {
                    skip_calc = true,
                    pinch_anim = true
                })
                return true
            end)
            return true
        end, {blockable = false, blocking = false})
    end
}

if next(SMODS.find_mod("FishAndChips")) then
    SMODS.Back{
        key = "fishtest",
        loc_txt = {
            name = "Fish test",
            text = {
                "Creates two random fish",
                "on game start, and when",
                "entering each blind"
            }
        },
        apply = function (self, back)
            TESTMOD4TESTING.event(function ()
                if not G.fac_fish_area then return false end
                for i=1,2 do
                    SMODS.add_card{
                        set = "fac_Fish"
                    }
                end
                return true
            end, {blocking = false, blockable = false})
        end,
        calculate = function (self, back, context)
            if context.setting_blind then
                print (G.GAME.round)
                for i=1,2 do
                    SMODS.add_card{
                        set = "fac_Fish"
                    }
                end

                if G.fac_fish_debug and G.P_CENTERS[G.fac_fish_debug] then
                    SMODS.add_card{
                        key = G.fac_fish_debug
                    }
                    G.fac_fish_debug = nil
                end
            end
        end
    }
end

SMODS.Joker{
    key = "testleg",
    loc_txt = {
        name = "Test Legend",
        text = {
            "It's legendary! :D"
        }
    },
    rarity = 4,
    loc_vars = function (self, info_queue, card)
        if next(SMODS.find_mod("FishAndChips")) then
            info_queue[#info_queue+1] = {key = "fish_fac_minty_kyriaki", set = "fac_Fish", config = {}}
            info_queue[#info_queue+1] = {key = "j_joker", set = "Joker", vars = {4}, config = {}}
        end
        
    end
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

function TESTMOD4TESTING.export_fucking_everything(mod_id, filter) --function(card) return card.children.center.atlas.px ~= 71 or card.children.center.atlas.py ~= 95 or not not next(card.config.center.display_size or {}) end
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
                    local clean_modname = modname:gsub(forbidden, "X")
                    local mod_filename = clean_modname
                    local alt_modname = clean_modname .. " (altered names)"
                    if name == "ERROR" then
                        sendWarnMessage("Unable to localize " .. k)
                        clean_name = k
                        clean_modname = alt_modname
                    end
                    if name ~= clean_name or modname ~= clean_modname then
                        print("Sanitized " .. name .. " from " .. modname ..
                        " as '" .. clean_name .. " (" .. mod_filename .. ")")
                        clean_modname = alt_modname
                    end

                    if not NFS.getInfo("exported card images/" .. clean_modname, "directory") then
                        NFS.createDirectory("exported card images/" .. clean_modname)
                    end

                    if not NFS.getInfo("exported card images/" .. clean_modname .. "/" .. (v.set), "directory") then
                        NFS.createDirectory("exported card images/" .. clean_modname .. "/" .. (v.set))
                    end

                    if not NFS.getInfo("exported card images/" .. clean_modname .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ").png") then
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

                                if NFS.getInfo("exported card images/" .. clean_modname .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ").png") then skip = true end
                            else
                                sendWarnMessage("Unable to get vars for " .. clean_name .. " from " .. clean_modname,
                                    "Test Mod (For Testing)")
                                clean_modname = alt_modname
                            end
                        end

                        if not skip then
                            local succ, res = pcall(SMODS.card_to_image, card, 1,
                                "exported card images/" ..
                                clean_modname .. "/" .. (v.set) .. "/" .. clean_name .. " (" .. mod_filename .. ")")
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
