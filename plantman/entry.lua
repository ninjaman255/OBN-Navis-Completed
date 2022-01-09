function package_init(package)
    package:declare_package_id("com.D3stroy3d.player.Plantman")
    package:set_special_description("Uncage your inner beast!")
    package:set_speed(5.0)
    package:set_attack(2)
    package:set_charged_attack(50)
    package:set_icon_texture(Engine.load_texture(_modpath.."plantman_face.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."plantman_OW.animation")
    package:set_overworld_texture_path(_modpath.."plantmanOW.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Plantman")
    player:set_health(2000)
    player:set_element(Element.Wood)
    player:set_height(60.0)
    player:set_animation(_modpath.."plantman.animation")
    player:set_texture(Engine.load_texture(_modpath.."plantman.png"), true)
    player:set_fully_charged_color(Color.new(232, 40, 128, 255))
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
end

function create_normal_attack(player)
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_charged_attack(player)
    local action = Battle.CardAction.new(player, "CHARGED_ATTACK")
    action:add_anim_action(6, function()
        local field = player:get_field()

        local player_team = player:get_team()
        local nearest_enemies = field:find_nearest_characters(player, function(character)
            local team = character:get_team()
            return team ~= Team.Other and player_team ~= team
        end)

        if #nearest_enemies == 0 then
            return
        end

        field:spawn(create_vine_spell(player), nearest_enemies[1]:get_tile())
    end)

    return action
end

function create_vine_spell(player)
    local spell = Battle.Spell.new(player:get_team())
    spell:set_facing(player:get_facing())
    spell:highlight_tile(Highlight.Flash)
    spell:set_hit_props(HitProps.new(
        player:get_attack_level() * 10,
        Hit.Impact | Hit.Stun,
        Element.Wood,
        player:get_id(),
        Drag.None
    ))

    local sprite = spell:sprite()
    sprite:set_texture(player:get_texture())
    sprite:set_layer(-5)

    local animation = spell:get_animation()
    animation:copy_from(player:get_animation())
    animation:set_state("VINES")
    animation:on_frame(2, function()
        spell:highlight_tile(Highlight.None)

        local tile = spell:get_tile()
        tile:attack_entities(spell)

        if tile:is_walkable() then
            tile:set_state(TileState.Grass)
        end
    end)
    animation:on_complete(function()
        spell:erase()
    end)

    return spell
end
