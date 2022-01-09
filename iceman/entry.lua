local attachment_texture = Engine.load_texture(_modpath .. "freezebomb/attachment.png")
local attachment_animation_path = _modpath .. "freezebomb/attachment.animation"
local explosion_sfx = Engine.load_audio(_modpath .. "freezebomb/explosion.ogg")
local throw_sfx = Engine.load_audio(_modpath .. "freezebomb/toss_item.ogg")
function package_init(package)
    package:declare_package_id("com.dawn.rescued.player.Iceman")
    package:set_special_description("Stay frosty!")
    package:set_speed(1.0)
    package:set_attack(1)
    package:set_charged_attack(10)
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."iceman_OW.animation")
    package:set_overworld_texture_path(_modpath.."iceman_OW.png")
    package:set_mugshot_texture_path(_modpath.."mug.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
end

function player_init(player)
    player:set_name("Iceman")
    player:set_health(1000)
    player:set_element(Element.Aqua)
    player:set_height(33.0)

    local base_texture = Engine.load_texture(_modpath.."Iceman_battle.png")
    local base_animation_path = _modpath.."Iceman_battle.animation"
    local base_charge_color = Color.new(0, 200, 255, 255)

    player:set_animation(base_animation_path)
    player:set_texture(base_texture, true)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -10)

    player.normal_attack_func = function(player)
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function(player)
		local action = Battle.CardAction.new(player, "PLAYER_THROW")
		action:set_lockout(make_animation_lockout())
		local override_frames = {{1,0.064},{2,0.064},{3,0.064},{4,0.064},{5,0.064}}
		local frame_data = make_frame_data(override_frames)
		action:override_animation_frames(frame_data)

		local hit_props = HitProps.new(
			player:get_attack_level() * 10,
			Hit.Impact | Hit.Freeze, 
			Element.Aqua,
			player:get_context(),
			Drag.None
		)

		action.execute_func = function(self, user)
			local attachment = self:add_attachment("HAND")
			local attachment_sprite = attachment:sprite()
			attachment_sprite:set_texture(attachment_texture)
			attachment_sprite:set_layer(-2)
			local ice_tower_texture = Engine.load_texture(_modpath .. "freezebomb/frost_tower.png")
			local ice_animation_path = _modpath .. "freezebomb/frost_tower.animation"
			local attachment_animation = attachment:get_animation()
			attachment_animation:load(attachment_animation_path)
			attachment_animation:set_state("DEFAULT")

			self:add_anim_action(3,function()
				attachment_sprite:hide()
				--self.remove_attachment(attachment)
				local tiles_ahead = 3
				local frames_in_air = 40
				local toss_height = 70
				local facing = user:get_facing()
				local target_tile = user:get_tile(facing,tiles_ahead)
				if not target_tile then
					return
				end
				action.on_landing = function ()
					if target_tile:is_walkable() then
						hit_explosion(user,target_tile,hit_props,ice_tower_texture,ice_animation_path,explosion_sfx)
					end
				end
				toss_spell(user,toss_height,attachment_texture,attachment_animation_path,target_tile,frames_in_air,action.on_landing)
			end)

			Engine.play_audio(throw_sfx, AudioPriority.Low)
		end
		return action
	end
	local snowman_spawned = false
	player.special_attack_func = function(player)
		if not snowman_spawned then
			local action = Battle.CardAction.new(player, "PLAYER_SPECIAL")
			action.execute_func = function(self, user)
				local tile = user:get_tile(user:get_facing(), 1)
				local query = function(ent)
					if Battle.Obstacle.from(ent) ~= nil or Battle.Character.from(ent) ~= nil then
						return true
					end
				end
				if tile and tile:is_walkable() and #tile:find_entities(query) <= 0 then
					local snowman = Battle.Obstacle.new(Team.Other)
					snowman:set_texture(base_texture, true)
					local animation = snowman:get_animation()
					animation:load(base_animation_path)
					animation:set_state("SNOWMAN_APPEAR")
					snowman:set_health(50)
					snowman:set_facing(Direction.Right)
					animation:on_complete(function()
						animation:set_state("SNOWMAN_IDLE")
						animation:set_playback(Playback.Loop)
						snowman_spawned = true
					end)
					snowman.update_func = function(self, dt)
						local tile = self:get_tile()
						tile:attack_entities(self)
						if not tile then
							self:erase()
						end
						if not tile:is_walkable() or tile:is_edge() then
							self:erase()
						end
					end
					snowman.attack_func = function(self)
						local tile = self:get_tile()
						local hitbox = Battle.Hitbox.new(Team.Other)
						local props = HitProps.new(
							50, 
							Hit.Impact | Hit.Flinch | Hit.Flash, 
							Element.Aqua,
							user:get_context(),
							Drag.new(snowman:get_facing(), 1)
						)
						hitbox:set_hit_props(props)
						user:get_field():spawn(hitbox, self:get_tile())
						self:delete()
					end
					snowman.delete_func = function(self)
						snowman_spawned = false
						self:erase()
					end
					snowman.can_move_to_func = function(self, tile)
						if tile then
							if not tile:is_walkable() or tile:is_edge() then
								return false
							end
						end
						return true
					end
					user:get_field():spawn(snowman, tile)
				end
			end
			return action
		else
			local action = Battle.CardAction.new(player, "PLAYER_KICK")
			action.execute_func = function(self, user)
				self:add_anim_action(3, function()
					local hit_props = HitProps.new(
						10,
						Hit.Impact | Hit.Breaking | Hit.Drag, 
						Element.Aqua,
						player:get_context(),
						Drag.new(user:get_facing(), 6)
					)
					local tile = user:get_tile(user:get_facing(), 1)
					local hitbox = Battle.Hitbox.new(user:get_team())
					hitbox:set_hit_props(hit_props)
					user:get_field():spawn(hitbox, tile)
				end)
			end
			return action
		end
	end
end

function toss_spell(tosser,toss_height,texture,animation_path,target_tile,frames_in_air,arrival_callback)
    local starting_height = -110
    local start_tile = tosser:get_current_tile()
    local field = tosser:get_field()
    local spell = Battle.Spell.new(tosser:get_team())
    local spell_animation = spell:get_animation()
    spell_animation:load(animation_path)
    spell_animation:set_state("DEFAULT")
    if tosser:get_height() > 1 then
        starting_height = -(tosser:get_height()+40)
    end

    spell.jump_started = false
    spell.starting_y_offset = starting_height
    spell.starting_x_offset = 10
    if tosser:get_facing() == Direction.Left then
        spell.starting_x_offset = -10
    end
    spell.y_offset = spell.starting_y_offset
    spell.x_offset = spell.starting_x_offset
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    spell:set_offset(spell.x_offset,spell.y_offset)

    spell.update_func = function(self)
        if not spell.jump_started then
            self:jump(target_tile, toss_height, frames(frames_in_air), frames(frames_in_air), ActionOrder.Voluntary)
            self.jump_started = true
        end
        if self.y_offset < 0 then
            self.y_offset = self.y_offset + math.abs(self.starting_y_offset/frames_in_air)
            self.x_offset = self.x_offset - math.abs(self.starting_x_offset/frames_in_air)
            self:set_offset(self.x_offset,self.y_offset)
        else
            arrival_callback()
            self:delete()
        end
    end
    spell.can_move_to_func = function(tile)
        return true
    end
    field:spawn(spell, start_tile)
end

function hit_explosion(user,target_tile,props,texture,anim_path,explosion_sound)
    local field = user:get_field()
    local spell = Battle.Spell.new(user:get_team())

    local spell_animation = spell:get_animation()
    spell_animation:load(anim_path)
    spell_animation:set_state("DEFAULT")
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    spell_animation:refresh(sprite)
	sprite:set_layer(-2)
    spell_animation:on_complete(function()
		spell:erase()
	end)

    spell:set_hit_props(props)
    spell.has_attacked = false
    spell.update_func = function(self)
        if not spell.has_attacked then
            Engine.play_audio(explosion_sound, AudioPriority.Highest)
            spell:get_current_tile():attack_entities(self)
            spell.has_attacked = true
        end
    end
    field:spawn(spell, target_tile)
end