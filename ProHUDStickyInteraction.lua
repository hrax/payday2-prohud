	ProHUDStickyInteraction = ProHUDStickyInteraction or {}
	if string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then
		-- Sticky Interaction clean up
		-- lib/units/beings/player/states/PlayerStandard
		local ProHUDPlayerStandard__start_action_interact = PlayerStandard._start_action_interact
		function PlayerStandard:_start_action_interact(t, ...)
			ProHUDStickyInteraction._lastInteractStart = ProHUDStickyInteraction._lastClick or 0;
			ProHUDPlayerStandard__start_action_interact(self, t, ...)
		end

		-- Sticky Interaction trigger
		-- lib/units/beings/player/states/PlayerStandard
		local ProHUDPlayerStandard__check_action_primary_attack = PlayerStandard._check_action_primary_attack
		function PlayerStandard:_check_action_primary_attack(t, input)
			local lastInteractionStart, lastClick = ProHUDStickyInteraction._lastInteractStart or 0, ProHUDStickyInteraction._lastClick or 0
			if input.btn_steelsight_press and self:_interacting() then
				if lastInteractionStart < lastClick then
					ProHUDStickyInteraction._lastClick = 0
					self:_interupt_action_interact()
				else
					ProHUDStickyInteraction._lastClick = t
				end
			end

			return ProHUDPlayerStandard__check_action_primary_attack(self, t, input)
		end

		-- Sticky Interaction trigger
		-- lib/units/beings/player/states/PlayerStandard
		local ProHUDPlayerStandard__interupt_action_interact = PlayerStandard._interupt_action_interact
		function PlayerStandard:_interupt_action_interact(t, input, complete)
			-- ProHUDStickyInteraction Execution
			local lastInteractionStart, lastClick = ProHUDStickyInteraction._lastInteractStart or 0, ProHUDStickyInteraction._lastClick or 0
			if not t and not complete and (lastInteractionStart < lastClick) then
				local caller = debug.getinfo(3,'n')
				caller = caller and caller.name
				--if caller == '_check_action_interact' then
				if caller == '_update_check_actions' then
					return -- ignore interruption
				end
			end
			ProHUDPlayerStandard__interupt_action_interact(self, t, input, complete)
		end
	elseif string.lower(RequiredScript) == "lib/managers/hud/hudinteraction" then
		local ProHUDHUDInteraction_init = HUDInteraction.init
		function HUDInteraction:init(hud, child_name)
			self._hud_panel = hud.panel
			self._circle_radius = 32
			self._sides = 32
			self._child_name_text = (child_name or "interact") .. "_text"
			self._child_ivalid_name_text = (child_name or "interact") .. "_invalid_text"
			if self._hud_panel:child(self._child_name_text) then
				self._hud_panel:remove(self._hud_panel:child(self._child_name_text))
			end
			if self._hud_panel:child(self._child_ivalid_name_text) then
				self._hud_panel:remove(self._hud_panel:child(self._child_ivalid_name_text))
			end
			local interact_text = self._hud_panel:text({
				name = self._child_name_text,
				visible = false,
				text = "HELLO",
				valign = "center",
				align = "center",
				layer = 1,
				color = Color.white,
				font = tweak_data.hud_present.text_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				h = 24
			})
			local invalid_text = self._hud_panel:text({
				name = self._child_ivalid_name_text,
				visible = false,
				text = "HELLO",
				valign = "center",
				align = "center",
				layer = 3,
				color = Color(1, 0.3, 0.3),
				blend_mode = "normal",
				font = tweak_data.hud_present.text_font,
				font_size = tweak_data.menu.pd2_small_font_size,
				h = 24
			})
			interact_text:set_y(self._hud_panel:h() / 2 + 24 + 16)
			invalid_text:set_center_y(interact_text:center_y())
		end

		function HUDInteraction:hide_interaction_bar(complete)
			if complete then
				local bitmap = self._hud_panel:bitmap({
					texture = "guis/textures/pd2/hud_progress_active",
					blend_mode = "add",
					align = "center",
					valign = "center",
					layer = 2,
					w = 64,
					h = 64
				})
				bitmap:set_position(bitmap:parent():w() / 2 - bitmap:w() / 2, bitmap:parent():h() / 2 - bitmap:h() / 2)
				
				local radius = 32
				local circle = CircleBitmapGuiObject:new(self._hud_panel, {
					radius = radius,
					sides = 32,
					current = 32,
					total = 32,
					color = Color.white:with_alpha(1),
					blend_mode = "normal",
					layer = 3
				})
				circle:set_position(self._hud_panel:w() / 2 - radius, self._hud_panel:h() / 2 - radius)
				bitmap:animate(callback(self, self, "_animate_interaction_complete"), circle)
			end
			if self._interact_circle then
				self._interact_circle:remove()
				self._interact_circle = nil
			end
		end

		function HUDInteraction:_animate_interaction_complete(bitmap, circle)
			local TOTAL_T = 0.6
			local t = TOTAL_T
			local mul = 1
			local c_x, c_y = bitmap:center()
			local size = bitmap:w()
			while t > 0 do
				local dt = coroutine.yield()
				t = t - dt
				mul = mul + dt * 0.75

				bitmap:set_size(size * mul, size * mul)
				bitmap:set_center(c_x, c_y)
				bitmap:set_alpha(math.max(t / TOTAL_T, 0))

				circle._circle:set_size(size * mul, size * mul)
				circle._circle:set_center(c_x, c_y)
				circle:set_current(1 - t / TOTAL_T)
				circle:set_alpha(math.max(t / TOTAL_T, 0))
			end
			bitmap:parent():remove(bitmap)
			circle:remove()
		end

		-- Sticky Interaction timer
		-- lib/managers/hud/HUDInteraction
		local ProHUDHUDInteraction_set_interaction_bar_width = HUDInteraction.set_interaction_bar_width
		function HUDInteraction:set_interaction_bar_width(current, total)
			local lastInteractionStart, lastClick = ProHUDStickyInteraction._lastInteractStart or 0, ProHUDStickyInteraction._lastClick or 0
			local sticky = (lastInteractionStart < lastClick)
			if self._interact_circle and self.__lastSticky ~= sticky then
				local img = sticky and 'guis/textures/pd2/hud_progress_invalid' or 'guis/textures/pd2/hud_progress_bg'

				local anim_func = function(o)
					while alive(o) and sticky do
						over(0.75, function(p)
							o:set_alpha(math.sin(p * 180) * 0.5 )
						end)
					end
				end

				local bg = self._interact_circle._bg_circle
				if bg and alive(bg) then
					bg:stop()
					bg:animate(anim_func)
					bg:set_image(img)
				end

				self.__lastSticky = sticky
			end

			ProHUDHUDInteraction_set_interaction_bar_width(self, current, total)
		end
	end
