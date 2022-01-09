local PLAYER_ELEVATION = 100
local STAR_ELEVATION = 100
local ANTIDAMAGE_LIFETIME = 10
local STAR_FRAME_DURATION = 10 -- looks like five frames
local TILE_WIDTH = 64

function package_init(package)
    package:declare_package_id("com.D3stroy3d.player.Shadowman")
    package:set_special_description("Uncage your inner beast!")
    package:set_speed(5.0)
    package:set_attack(2)
    package:set_charged_attack(50)
    package:set_icon_texture(Engine.load_texture(_modpath.."shadowman_face.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."shadowman_ow.animation")
    package:set_overworld_texture_path(_modpath.."shadowman.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Shadowman")
    player:set_health(2000)
    player:set_element(Element.Sword)
    player:set_height(80.0)
    player:set_animation(_modpath.."shadowman.animation")
    player:set_texture(Engine.load_texture(_modpath.."shadowman_atlas.png"), true)
    player:set_fully_charged_color(Color.new(255,0,0,255))
    player:show_shadow(true)
    player:set_shadow(Engine.load_texture(_modpath.."shadow.png"))
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack
    player.floating = false
    player.special_sfx = Engine.load_audio(_modpath.."panel_crack.ogg")

    local antidamage = Battle.DefenseRule.new(0, DefenseOrder.Always)
    player.antidamage_active = 0

    antidamage.can_block_func = function(judge, attacker)
        if player.floating then
            judge:block_impact()
            judge:block_damage()
        end

        if player.antidamage_active == 0 then
            return
        end

        local hitprops = attacker:copy_hit_props()

        if hitprops.element == Element.Cursor then
            judge:signal_defense_was_pierced()
            return
        end

        --  must be impact and deal >= 10 damage
        if hitprops.flags & Hit.Impact ~= Hit.Impact and hitprops.damage < 10 then return end

        judge:block_impact()
        judge:block_damage()

        local attack_owner = player:get_field():get_entity(hitprops.aggressor)

        player:card_action_event(create_star_action(player, attack_owner), ActionOrder.Voluntary)
        player.antidamage_active = 0
    end

    player.update_func = function()
        if player.antidamage_active > 0 then
            player.antidamage_active = player.antidamage_active - 1
        end
    end

    player:add_defense_rule(antidamage)
end

function create_normal_attack(player)
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_charged_attack(player)
    local field = player:get_field()
    local player_team = player:get_team()
    local nearest_enemies = field:find_nearest_characters(player, function(character)
        local team = character:get_team()
        return team ~= Team.Other and player_team ~= team
    end)

    return create_star_action(player, nearest_enemies[1])
end

function create_special_attack(player)
    player.antidamage_active = ANTIDAMAGE_LIFETIME
    return nil
end

function create_star_action(player, target_entity)
    if not target_entity then
        -- do nothing, since there's nothing to attack
        return nil
    end

    local action = Battle.CardAction.new(player, "PLAYER_SPECIAL")

    local target_tile = target_entity:get_tile()

    action.execute_func = function()
        player.floating = true
        player:set_elevation(PLAYER_ELEVATION)

        local field = player:get_field()
        field:spawn(create_poof(), player:get_tile())
        field:spawn(create_star(player, target_tile), target_tile)
        Engine.play_audio(player.special_sfx, AudioPriority.Highest)
    end

    action.action_end_func = function()
        player.floating = false
        player:set_elevation(0)
    end


    return action
end

function create_star(player, target_tile)
    local star = Battle.Spell.new(player:get_team())

    local sprite = star:sprite()
    sprite:set_texture(Engine.load_texture(_modpath.."ninja_star_atlas.png"))
    sprite:set_layer(-5)

    local animation = star:get_animation()
    animation:load(_modpath.."ninja_star.animation")
    animation:set_state("DEFAULT")

    local tile_offset = player:get_tile():x() - target_tile:x()
    local x_offset = tile_offset * TILE_WIDTH
    star:set_offset(x_offset, 0)
    star:set_elevation(100)
    star:set_facing(Direction.Right)
    star:highlight_tile(Highlight.Solid)
    star:set_hit_props(HitProps.new(
        10 * player:get_attack_level(),
        Hit.Impact,
        Element.None,
        player:get_id(),
        Drag.None
    ))

    local lifetime = 0

    star.update_func = function()
        if lifetime > STAR_FRAME_DURATION then
            return
        end

        local progress = lifetime / STAR_FRAME_DURATION
        star:set_elevation(STAR_ELEVATION * (1 - progress))
        star:set_offset(x_offset * (1 - progress), 0)

        lifetime = lifetime + 1

        if lifetime > STAR_FRAME_DURATION then
            target_tile:attack_entities(star)
            animation:set_state("GROUNDED")
            animation:on_complete(function()
                star:erase()
            end)
        end
    end

    return star
end

function create_poof()
    local poof = Battle.Artifact.new()
    poof:set_offset(0, -70)
    poof:set_facing(Direction.Right)
    poof:sprite():set_texture(Engine.load_texture(_modpath.."poof.png"))

    local poof_animation = poof:get_animation()
    poof_animation:load(_modpath.."poof.animation")
    poof_animation:set_state("DEFAULT")
    poof_animation:on_complete(function()
        poof:erase()
    end)

    return poof
end
