function package_init(package)
    package:declare_package_id("com.D3stroy3d.player.Gateman")
    package:set_special_description("Uncage your inner beast!")
    package:set_speed(5.0)
    package:set_attack(2)
    package:set_charged_attack(50)
    --package:set_icon_texture(Engine.load_texture(_modpath.."fireman_face.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."GatemanCard.animation")
    package:set_overworld_texture_path(_modpath.."GatemanCard.png")
    package:set_mugshot_texture_path(_modpath.."mugV1.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Gateman")
    player:set_health(2000)
    player:set_element(Element.Break)
    player:set_height (60.0)
    player:set_animation(_modpath.."gateman.animation")
    player:set_texture(Engine.load_texture(_modpath.."gateman.png"), true)
    player:set_fully_charged_color(Color.new(64, 184, 140, 255))
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
    player.special_attack_func = create_special_attack


    player.update_func = function(self, dt) 
        -- nothing in particular
    end
end

function create_normal_attack(player)
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_charged_attack(player)
    local action = Battle.CardAction.new(player, "SPAWN_SOLDIERS")

    local field = player:get_field()

    action:add_anim_action(8, function()
        field:spawn(create_soldier(player), player:get_tile())
    end)

    action:add_anim_action(13, function()
        field:spawn(create_soldier(player), player:get_tile())
    end)

    action:add_anim_action(18, function()
        field:spawn(create_soldier(player), player:get_tile())
    end)

    return action
end

function create_special_attack(player)
    return nil
end

function create_soldier(player)
    local soldier = Battle.Obstacle.new(player:get_team())
    soldier:set_facing(player:get_facing())
    soldier:share_tile(true)
    soldier:set_health(10 * player:get_attack_level())
    soldier:set_hit_props(HitProps.new(
        10 * player:get_attack_level(),
        Hit.Impact,
        Element.None,
        player:get_id(),
        Drag.None
    ))

    local sprite = soldier:sprite()
    sprite:set_texture(player:get_texture())
    sprite:set_layer(-4)

    local animation = soldier:get_animation()
    animation:copy_from(player:get_animation())
    animation:set_state("SOLDIER_RUN")
    animation:set_playback(Playback.Loop)

    soldier.can_move_to_func = function()
        return true
    end

    soldier.update_func = function()
        local current_tile = soldier:get_tile()
        current_tile:attack_entities(soldier)

        if current_tile:is_hole() then
            soldier:erase()
            return
        end

        if soldier:is_moving() then return end

        -- finding a target to move towards
        local soldier_team = soldier:get_team()
        local facing_direction = soldier:get_facing()

        local nearby_enemies = soldier:get_field():find_nearest_characters(soldier, function(character)
            local team = character:get_team()

            if soldier_team == team or team == Team.Other then
                -- needs to be opposing team
                return false
            end

            if facing_direction == Direction.Left and current_tile:x() <= character:get_tile():x() then
                -- passed this opponent
                return false
            elseif current_tile:x() >= character:get_tile():x() then
                -- passed this opponent
                return false
            end

            -- we can target this character
            return true
        end)


        local direction = facing_direction

        -- target enemy
        if #nearby_enemies ~= 0 then
            local current_y = current_tile:y()
            local target_y = nearby_enemies[1]:get_tile():y()

            if target_y > current_y then
                direction = Direction.join(direction, Direction.Down)
            elseif target_y < current_y then
                direction = Direction.join(direction, Direction.Up)
            end
        end -- otherwise just travel in the facing directions

        local next_tile = soldier:get_tile(direction, 1)

        if next_tile == nil then
            soldier:erase()
            return
        end

        soldier:slide(next_tile, frames(40), frames(0), ActionOrder.Voluntary, function() end)
    end

    soldier.delete_func = function()
        local explosion = Battle.Explosion.new(1, 1)
        local offset = soldier:get_offset()
        explosion:set_offset(offset.x, offset.y)
        soldier:get_field():spawn(explosion, soldier:get_tile())
    end

    return soldier
end