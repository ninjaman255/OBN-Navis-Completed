-- todo:
-- sound effects
-- small top
-- make top form invulnerable

function package_init(package)
    package:declare_package_id("com.D3stroy3d.player.Topman")
    package:set_special_description("Uncage your inner beast!")
    package:set_speed(5.0)
    package:set_attack(2)
    package:set_charged_attack(50)
    package:set_icon_texture(Engine.load_texture(_modpath.."topman_face.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."topmanOW.animation")
    package:set_overworld_texture_path(_modpath.."topmanOW.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Topman")
    player:set_health(2000)
    player:set_element(Element.Break)
    player:set_height(46.0)
    player:set_animation(_modpath.."topman.animation")
    player:set_texture(Engine.load_texture(_modpath.."topman_atlas.png"), true)
    player:set_charge_position(0, -20)
    player:set_fully_charged_color(Color.new(136, 152, 176, 255))
    player.normal_attack_func = create_normal_attack
    player.charged_attack_func = create_charged_attack
end

function create_normal_attack(player)
    return Battle.Buster.new(player, false, player:get_attack_level())
end

function create_charged_attack(player)
    local action = Battle.CardAction.new(player, "RETURN_TO_TOP")
    action:set_lockout(make_sequence_lockout())

    local animation_completed = false
    local animation = player:get_animation()
    local traveling_forward = true
    local start_tile = nil
    local top = create_top_double(player)
    local attack_spell = nil
    local field = player:get_field()

    action.execute_func = function()
        animation:on_complete(function()
            animation_completed = true
        end)
    end

    local action_end_func = function()
        -- clean up
        if attack_spell and not attack_spell:is_deleted() then
            attack_spell:erase()
        end

        if not top:is_deleted() then
            top:erase()
        end

        if start_tile and not start_tile:contains_entity(player) then
            start_tile:add_entity(player)
        end
    end

    -- step1 -> waiting for the transformation to end
    local step1 = Battle.Step.new()
    step1.update_func = function(self)
        if animation_completed then
            start_tile = player:get_tile()
            -- prevent other entities from walking here so we can return
            start_tile:reserve_entity_by_id(player:get_id())

            -- spawn the top
            local top_anim = top:get_animation()
            top_anim:set_state("TRUE_FORM")
            top_anim:set_playback(Playback.Loop)
            field:spawn(top, start_tile)

            -- remove the player from the field to prevent ourselves from getting hit
            start_tile:remove_entity_by_id(player:get_id())

            self:complete_step()
        end
    end
    action:add_step(step1)

    -- step2 -> movement + attack
    -- is really just the top's update_func
    local last_tile = player:get_tile()

    local function complete_top_step()
        start_tile:add_entity(player)
        top:erase()
    end

    top.update_func = function()
        -- -- handling the attack
        local current_tile = top:get_tile()

        if attack_spell then
            if current_tile ~= last_tile then
                -- need a new spell for the new tile
                attack_spell:erase()
                attack_spell = create_hitbox(player)
                field:spawn(attack_spell, current_tile)
            end
        else
            attack_spell = create_hitbox(player)
            field:spawn(attack_spell, current_tile)
        end

        last_tile = current_tile

        if attack_spell:get_tile() ~= nil then
            current_tile:attack_entities(attack_spell)
        end

        -- -- handling movement
        if player:is_moving() then
            return
        end

        local direction = player:get_facing()

        if not traveling_forward then
            if current_tile == start_tile then
                -- made it back
                complete_top_step()
                return
            end

            direction = Direction.reverse(direction)
        end

        local next_tile = top:get_tile(direction, 1)

        if not next_tile:is_walkable() then
            if traveling_forward then
                traveling_forward = false
                direction = Direction.reverse(direction)
                next_tile = top:get_tile(direction, 1)
            else
                complete_top_step()
                return
            end
        end

        top:slide(
            next_tile,
            frames(16),
            frames(0),
            ActionOrder.Voluntary,
            function() end
        )
    end
    top.delete_func = action_end_func

    -- step3 -> transforming back
    local step3 = Battle.Step.new()
    step3.update_func = function(self)
        if attack_spell and not attack_spell:is_deleted() then
            attack_spell:erase()
        end

        animation:set_state("RETURN_TO_MAN")
        animation:set_playback(Playback.Once)

        animation_completed = false
        animation:on_complete(function()
            animation_completed = true
        end)

        self:complete_step()
    end
    action:add_step(step3)

    -- step4 - wait for animation to complete
    local step4 = Battle.Step.new()
    step4.update_func = function(self)
        if animation_completed then
            self:complete_step()
        end
    end
    action:add_step(step4)

    action.action_end_func = action_end_func

    return action
end

function create_special_attack(player)
    print("execute special")
    return nil
end

function create_top_double(player)
    local top = Battle.Obstacle.new(player:get_team())
    top:set_facing(player:get_facing())
    top:share_tile(true)

    local sprite = top:sprite()
    sprite:set_texture(player:get_texture())

    local animation = top:get_animation()
    animation:copy_from(player:get_animation())

    top.can_move_to_func = function()
        return true
    end

    return top
end

function create_hitbox(player)
    local hitbox = Battle.Spell.new(player:get_team())

    hitbox:set_hit_props(
        HitProps.new(
            10 * player:get_attack_level(),
            Hit.Impact | Hit.Flinch | Hit.Flash,
            Element.Break,
            player:get_id(),
            Drag.None
        )
    )

    return hitbox
end
