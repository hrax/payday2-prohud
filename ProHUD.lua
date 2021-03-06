if not ProHUD then dofile( ModPath .. "static.lua") end

if RequiredScript == "lib/managers/hudmanagerpd2" then
	HUDManager.PROHUD = true --External flag
	HUDManager._USE_KILL_COUNTER = HUDManager._USE_KILL_COUNTER or false    --Updated on kill counter plugin load

	local update_original = HUDManager.update
	local set_stamina_value_original = HUDManager.set_stamina_value
	local set_max_stamina_original = HUDManager.set_max_stamina
	local add_weapon_original = HUDManager.add_weapon

	function HUDManager:hide_player_gear(panel_id)
		if self._teammate_panels[panel_id] and self._teammate_panels[panel_id]:panel() and self._teammate_panels[panel_id]:panel():child("player") then
			local player_panel = self._teammate_panels[panel_id]:panel():child("player")
			player_panel:child("weapons_panel"):set_visible(false)
			player_panel:child("equipment_panel"):child("deployable_equipment_panel"):set_visible(false)
			player_panel:child("equipment_panel"):child("cable_ties_panel"):set_visible(false)
			player_panel:child("equipment_panel"):child("grenades_panel"):set_visible(false)
		end
	end
	function HUDManager:show_player_gear(panel_id)
		if self._teammate_panels[panel_id] and self._teammate_panels[panel_id]:panel() and self._teammate_panels[panel_id]:panel():child("player") then
			local player_panel = self._teammate_panels[panel_id]:panel():child("player")
			player_panel:child("weapons_panel"):set_visible(true)
			player_panel:child("equipment_panel"):child("deployable_equipment_panel"):set_visible(true)
			player_panel:child("equipment_panel"):child("cable_ties_panel"):set_visible(true)
			player_panel:child("equipment_panel"):child("grenades_panel"):set_visible(true)
		end
	end

	function HUDManager:_create_teammates_panel(hud)
		local hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self._hud.teammate_panels_data = self._hud.teammate_panels_data or {}
		self._teammate_panels = {}
	   
		if hud.panel:child("teammates_panel") then     
				hud.panel:remove(hud.panel:child("teammates_panel"))
		end

		local teammates_panel = hud.panel:panel({
			name = "teammates_panel",
			h = hud.panel:h(),
			halign = "grow",
			valign = "bottom"
		})

		local num_panels = CriminalsManager and CriminalsManager.MAX_NR_CRIMINALS or 4
		for i = 1, math.max(num_panels, HUDManager.PLAYER_PANEL) do
			local is_player = i == HUDManager.PLAYER_PANEL
			-- do break end
			
			-- unhandled boolean indicator
			self._hud.teammate_panels_data[i] = {
				taken = false,
				special_equipments = {}
			}
			
			local g = 20
			local teammate = HUDTeammate:new(i, teammates_panel, is_player)

			local x = math.floor((teammate:w() + g) * (i - 1))
			teammate._panel:set_x(math.min(teammates_panel:w() - teammate:w(), math.floor(x)))
			if is_player then
				teammate._panel:set_x(teammates_panel:w() - teammate:w())
			end

			table.insert(self._teammate_panels, teammate)
			
			if is_player then
				teammate:add_panel()
			end
		end
	end

	function HUDManager:update(t, dt, ...)
			self._next_latency_update = self._next_latency_update or 0

			local session = managers.network:session()
			if session and self._next_latency_update <= t then
					self._next_latency_update = t + 1
					local latencies = {}
					for _, peer in pairs(session:peers()) do
							if peer:id() ~= session:local_peer():id() then
									latencies[peer:id()] = Network:qos(peer:rpc()).ping
							end
					end
				   
					for i, panel in ipairs(self._teammate_panels) do
							local latency = latencies[panel:peer_id()]
							if latency then
									self:update_teammate_latency(i, latency)
							end
					end
			end
		   
			--[[
			for i = 1, #self._teammate_panels do
					self._teammate_panels[i]:update(t, dt)
			end
			]]
		   
			return update_original(self, t, dt, ...)
	end

	--[[function HUDManager:set_stamina_value(value, ...)
			self._teammate_panels[HUDManager.PLAYER_PANEL]:set_current_stamina(value)
		   
			return set_stamina_value_original(self, value, ...)
	end

	function HUDManager:set_max_stamina(value, ...)
			self._teammate_panels[HUDManager.PLAYER_PANEL]:set_max_stamina(value)
		   
			return set_max_stamina_original(self, value, ...)
	end]]

	function HUDManager:add_weapon(data, ...)
			local selection_index = data.inventory_index
			local weapon_id = data.unit:base().name_id
			local silencer = data.unit:base():got_silencer()
			self:set_teammate_weapon_id(HUDManager.PLAYER_PANEL, selection_index, weapon_id, silencer)

			return add_weapon_original(self, data, ...)
	end

	function HUDManager:set_teammate_carry_info(i, carry_id, value, override_main)
			if i ~= HUDManager.PLAYER_PANEL or override_main then
					self._teammate_panels[i]:set_carry_info(carry_id, value)
			end
	end

	function HUDManager:remove_teammate_carry_info(i)
			self._teammate_panels[i]:remove_carry_info()
	end

	function HUDManager:set_teammate_weapon_id(i, slot, id, silencer)
			self._teammate_panels[i]:set_weapon_id(slot, id, silencer)
	end

	function HUDManager:update_teammate_latency(i, value)
			self._teammate_panels[i]:update_latency(value)
	end

	function HUDManager:set_mugshot_voice(id, active)
			local panel_id
			for _, data in pairs(managers.criminals:characters()) do
					if data.data.mugshot_id == id then
							panel_id = data.data.panel_id
							break
					end
			end

			if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
					self._teammate_panels[panel_id]:set_voice_com(active)
			end
	end

	function HUDManager:get_teammate_carry_panel_info(i)
			return self._teammate_panels[i]:get_carry_panel_info()
	end

	function HUDManager:reposition_objective()
		self._hud_objectives:reposition_objective()
	end

elseif RequiredScript == "lib/managers/hud/hudteammate" then
		HUDTeammate._NAME_ANIMATE_SPEED = 90
	HUDTeammate._INTERACTION_TEXTS = {
			big_computer_server = "USING COMPUTER",
	--[[
			ammo_bag = "Using ammo bag",
			c4_bag = "Taking C4",
			c4_mission_door = "Planting C4 (equipment)",
			c4_x1_bag = "Taking C4",
			connect_hose = "Connecting hose",
			crate_loot = "Opening crate",
			crate_loot_close = "Closing crate",
			crate_loot_crowbar = "Opening crate",
			cut_fence = "Cutting fence",
			doctor_bag = "Using doctor bag",
			drill = "Placing drill",
			drill_jammed = "Repairing drill",
			drill_upgrade = "Upgrading drill",
			ecm_jammer = "Placing ECM jammer",
			first_aid_kit = "Using first aid kit",
			free = "Uncuffing",
			grenade_briefcase = "Taking grenade",
			grenade_crate = "Opening grenade case",
			hack_suburbia_jammed = "Resuming hack",
			hold_approve_req = "Approving request",
			hold_close = "Closing door",
			hold_close_keycard = "Closing door (keycard)",
			hold_download_keys = "Starting hack",
			hold_hack_comp = "Starting hack",
			hold_open = "Opening door",
			hold_open_bomb_case = "Opening bomb case",
			hold_pku_disassemble_cro_loot = "Disassembling bomb",
			hold_remove_armor_plating = "Removing plating",
			hold_remove_ladder = "Taking ladder",
			hold_take_server_axis = "Taking server",
			hostage_convert = "Converting enemy",
			hostage_move = "Moving hostage",
			hostage_stay = "Moving hostage",
			hostage_trade = "Trading hostage",
			intimidate = "Cable tying civilian",
			open_train_cargo_door = "Opening door",
			pick_lock_easy_no_skill = "Picking lock",
			requires_cable_ties = "Cable tying civilian",
			revive = "Reviving",
			sentry_gun_refill = "Refilling sentry gun",
			shaped_charge_single = "Planting C4 (deployable)",
			shaped_sharge = "Planting C4 (deployable)",
			shape_charge_plantable = "Planting C4 (equipment)",
			shape_charge_plantable_c4_1 = "Planting C4 (equipment)",
			shape_charge_plantable_c4_x1 = "Planting C4 (equipment)",
			trip_mine = "Placing trip mine",
			uload_database_jammed = "Resuming hack",
			use_ticket = "Using ticket",
			votingmachine2 = "Starting hack",
			votingmachine2_jammed = "Resuming hack",
			methlab_caustic_cooler = "Cooking meth (caustic soda)",
			methlab_gas_to_salt = "Cooking meth (hydrogen chloride)",
			methlab_bubbling = "Cooking meth (muriatic acid)",
			money_briefcase = "Opening briefcase",
			pku_barcode_downtown = "Taking barcode (downtown)",
			pku_barcode_edgewater = "Taking barcode (?)",   --TODO: Location
			gage_assignment = "Taking courier package",
			stash_planks = "Boarding window",
			stash_planks_pickup = "Taking planks",
			taking_meth = "Bagging loot",
			hlm_connect_equip = "Connecting cable",
	]]
	}

	local function debug_check_tweak_data(tweak_data_id)
			if (rawget(_G, "DEBUG_MODE") ~= nil) and tweak_data_id and tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].timer --[[and tweak_data.interaction[tweak_data_id].timer > 1]] then
					if not (tweak_data.interaction[tweak_data_id].action_text_id or HUDTeammate._INTERACTION_TEXTS[tweak_data_id]) then
							debug_log("interactions.log", "%s - %s - %s\n", tweak_data_id, managers.job:current_level_id(), tweak_data.interaction[tweak_data_id].timer)
					end
			end
	end

	function HUDTeammate:init( i , teammates_panel , is_player )
			self._parent = teammates_panel
			self._id = i
			self._main_player = is_player and true or false
			self._timer = 0
			self._special_equipment = {}
			
			-- Debug teammate
			if self._main_player then
				--self._main_player = false
			end

			self:load_options(true) -- force load options

			self:_create_main_panel()
			self:_create_panels()
			self:_place_panels()
			self:reset_kill_count()
	end

	function HUDTeammate:load_options( force )
		self._scale = self._main_player and 1 or 0.8
		self._opacity = self._main_player and 1 or 0.6
		self._bg_opacity = self._opacity * 0.3

		-- configure some of the panel properties here
		self._outer_spacer = 1
		self._inner_spacer = 5

		self._health_panel_w = 64 * self._scale
		self._health_panel_h = 64 * self._scale

		-- todo: separate weapons_panel into 2 widths; weapon icon + ammo + ammo
		self._weapons_panel_icon_w = 100 * self._scale
		self._weapons_panel_clip_w = self._main_player and 40 or 0 * self._scale
		self._weapons_panel_ammo_w = self._main_player and 30 or 35 * self._scale

		self._weapons_panel_w = self._weapons_panel_icon_w + self._weapons_panel_ammo_w + self._weapons_panel_clip_w + self._outer_spacer -- one spacer in this panel...
		self._weapons_panel_h = self._health_panel_h

		self._equipment_panel_w = 50 * self._scale
		self._equipment_panel_h = self._health_panel_h

		self._name_panel_h = 15
		self._special_equipment_panel_h = 20
		self._carry_panel_h = 22

		-- Totals...
		self._max_w = self._health_panel_w + self._inner_spacer + self._weapons_panel_w + self._outer_spacer + self._equipment_panel_w
		self._max_h = self._health_panel_h + self._inner_spacer + self._name_panel_h + self._outer_spacer + self._special_equipment_panel_h + self._inner_spacer + self._carry_panel_h

		self._callsign_txt = "guis/textures/pd2/risklevel_deathwish_blackscreen"
		self._callsign_txt_rect = {0, 0, 64, 64}

		if not self._main_player then
			self._max_w = self._health_panel_w + self._inner_spacer + self._weapons_panel_w + self._outer_spacer + self._equipment_panel_w + self._inner_spacer + self._health_panel_w
			self._max_h = self._health_panel_h + self._inner_spacer + self._name_panel_h + self._inner_spacer + self._carry_panel_h

			self._callsign_txt = "guis/textures/pd2/risklevel_blackscreen"
			--self._callsign_txt_rect = {0, 0, 16, 16}
		end
	end

	function HUDTeammate:_create_main_panel()
		self._panel = self._parent:panel({
			visible = false,
			name = "teammate_panel_" .. self._id,
			w = self._max_w,
			h = self._max_h,
			x = 0,
			--y = 0,
			alpha = self._opacity,
			halign = "right",
			valign = "bottom"
		})
		self._panel:set_y(self._parent:h() - self._panel:h())

		if not self._main_player then
			self._panel:set_halign("left")
		end
		self._player_panel = self._panel:panel({name = "player"})
	end

	function HUDTeammate:_create_panels()
		-- main hud panels (the very bottom row)
		self:_create_health_panel()
		self:_create_weapons_panel()
		self:_create_equipment_panel()

		-- top panels
		self:_create_carry_panel()
		self:_create_special_equipment_panel()
		self:_create_name_panel()

		-- specials
		self:_create_latency_panel()
		self:_create_kills_panel()
		self:_create_interact_panel_new()
	end

	function HUDTeammate:_place_panels()
		local panel = self._player_panel

		--[[
			Place panels
		]]--
		--if self._main_player then
			self._health_panel:set_left(0)
			self._health_panel:set_bottom(panel:h())

			self._weapons_panel:set_left(self._health_panel:right() + self._inner_spacer)
			self._weapons_panel:set_bottom(panel:h())

			self._equipment_panel:set_left(self._weapons_panel:right() + self._outer_spacer)
			self._equipment_panel:set_bottom(panel:h())
			
			-- 

			self._name_panel:set_left(0)
			self._name_panel:set_bottom(self._health_panel:top() - self._inner_spacer)

			--

			self._special_equipment_panel:set_bottom(self._name_panel:top() - self._inner_spacer)
			self._special_equipment_panel:set_left(0)

			--
			
			self._carry_panel:set_top(0)
			self._carry_panel:set_right(self._equipment_panel:right())

			-- hide additional
			if not self._main_player then
				self._carry_panel:set_left(0)

				self._special_equipment_panel:set_top(self._health_panel:top())
				self._special_equipment_panel:set_left(self._equipment_panel:right() + self._inner_spacer)

				self._interact_panel:set_top(self._weapons_panel:top())
				self._interact_panel:set_left(self._weapons_panel:left()) 
			end

			self._kills_panel:set_visible(false)
			self._latency_panel:set_visible(false)
			self._interact_panel:set_visible(false)
			
			self._latency_panel:set_center(self._health_panel:center())
		--[[else
			self._health_panel:set_left(0)
			self._health_panel:set_bottom(panel:h())

			self._weapons_panel:set_left(middle_top)
			self._special_equipment_panel:set_top(0)

			self._weapons_panel:set_left(self._health_panel:right() + ProHUDOptions.PANEL_GAP)
			self._special_equipment_panel:set_left(self._weapons_panel:right() + ProHUDOptions.PANEL_GAP)

			-- place top panels
			self._name_panel:set_left(0)
			self._name_panel:set_top(0)
			self._equipment_panel:set_right(self._weapons_panel:right())
			self._equipment_panel:set_top(0)

			-- place bottom panels
			self._latency_panel:set_left(0)
			self._latency_panel:set_bottom(panel:h())
			self._kills_panel:set_left(self._weapons_panel:left())
			self._kills_panel:set_bottom(panel:h())
			self._carry_panel:set_right(self._weapons_panel:right())
			self._carry_panel:set_bottom(panel:h())

			-- place interact panel
			
		end]]--
	end

	function HUDTeammate:w()
		return self._max_w
	end

	function HUDTeammate:h()
		return self._max_h
	end

	function HUDTeammate:_create_health_panel()
		self._health_panel = self._player_panel:panel({
				name = "radial_health_panel",
				h = self._health_panel_h,
				w = self._health_panel_w,
		})

		local health_panel_bg = self._health_panel:bitmap({
				name = "radial_bg",
				texture = "guis/textures/pd2/hud_radialbg",
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 0,
		})
		   
		local radial_health = self._health_panel:bitmap({
				name = "radial_health",
				texture = "guis/textures/pd2/hud_health",
				texture_rect = { 64, 0, -64, 64 },
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				color = Color(1, 1, 0, 0),
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 2,
		})
		   
		local radial_shield = self._health_panel:bitmap({
				name = "radial_shield",
				texture = "guis/textures/pd2/hud_shield",
				texture_rect = { 64, 0, -64, 64 },
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				color = Color(1, 1, 0, 0),
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 1
		})
		   
		local damage_indicator = self._health_panel:bitmap({
				name = "damage_indicator",
				texture = "guis/textures/pd2/hud_radial_rim",
				blend_mode = "add",
				color = Color(1, 1, 1, 1),
				alpha = 0,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 1
		})

		local radial_custom = self._health_panel:bitmap({
				name = "radial_custom",
				texture = "guis/textures/pd2/hud_swansong",
				texture_rect = { 0, 0, 64, 64 },
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				color = Color(1, 0, 0, 0),
				visible = false,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 2
		})
		   
		self._condition_icon = self._health_panel:bitmap({
				name = "condition_icon",
				layer = 4,
				visible = false,
				color = Color.white,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
		})
		
		self._condition_timer = self._health_panel:text({
				name = "condition_timer",
				visible = false,
				layer = 5,
				color = Color.white,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				align = "center",
				vertical = "center",
				font_size = self._health_panel:h() * 0.5,
				font = tweak_data.hud_players.timer_font
		})

		if self._main_player then
			local radial_rip = self._health_panel:bitmap({
				name = "radial_rip",
				texture = "guis/textures/pd2/hud_rip",
				texture_rect = {
					64,
					0,
					-64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 3
			})
			radial_rip:set_color(Color(1, 0, 0, 0))
			radial_rip:hide()
			local radial_rip_bg = self._health_panel:bitmap({
				name = "radial_rip_bg",
				texture = "guis/textures/pd2/hud_rip_bg",
				texture_rect = {
					64,
					0,
					-64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "normal",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 1
			})
			radial_rip_bg:set_color(Color(1, 0, 0, 0))
			radial_rip_bg:hide()
		end
			local radial_absorb_shield_active = self._health_panel:bitmap({
				name = "radial_absorb_shield_active",
				texture = "guis/dlcs/coco/textures/pd2/hud_absorb_shield",
				texture_rect = {
					0,
					0,
					64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "normal",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 5
			})
			radial_absorb_shield_active:set_color(Color(1, 0, 0, 0))
			radial_absorb_shield_active:hide()
			local radial_absorb_health_active = self._health_panel:bitmap({
				name = "radial_absorb_health_active",
				texture = "guis/dlcs/coco/textures/pd2/hud_absorb_health",
				texture_rect = {
					0,
					0,
					64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "normal",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 5
			})
			radial_absorb_health_active:set_color(Color(1, 0, 0, 0))
			radial_absorb_health_active:hide()
			radial_absorb_health_active:animate(callback(self, self, "animate_update_absorb_active"))
			local radial_info_meter = self._health_panel:bitmap({
				name = "radial_info_meter",
				texture = "guis/dlcs/coco/textures/pd2/hud_absorb_stack_fg",
				texture_rect = {
					0,
					0,
					64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "add",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 3
			})
			radial_info_meter:set_color(Color(1, 0, 0, 0))
			radial_info_meter:hide()
			local radial_info_meter_bg = self._health_panel:bitmap({
				name = "radial_info_meter_bg",
				texture = "guis/dlcs/coco/textures/pd2/hud_absorb_stack_bg",
				texture_rect = {
					64,
					0,
					-64,
					64
				},
				render_template = "VertexColorTexturedRadial",
				blend_mode = "normal",
				alpha = 1,
				w = self._health_panel:w(),
				h = self._health_panel:h(),
				layer = 1
			})
			radial_info_meter_bg:set_color(Color(1, 0, 0, 0))
			radial_info_meter_bg:hide()
	end

	function HUDTeammate:_create_weapons_panel()
		
		local function populate_weapon_panel(panel, equipped)
			local teammate = self._main_player and false or true

			local in_spacer = (self._main_player and self._inner_spacer or self._outer_spacer)
			local h_spaced = panel:h() - (in_spacer * 2)

			local weapon_bg = panel:rect({
				name = "weapon_bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = self._bg_opacity,
				h = panel:h(),
				w = self._weapons_panel_icon_w,
				layer = -1,
			})

			local mag_bg = panel:rect({
				name = "mag_bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = self._bg_opacity,
				h = panel:h(),
				w = self._weapons_panel_clip_w + (equipped and 0 or self._outer_spacer),
				layer = -1,
			})
			mag_bg:set_left(weapon_bg:right())

			local ammo_bg = panel:rect({
				name = "ammo_bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = self._bg_opacity,
				h = panel:h(),
				w = self._weapons_panel_ammo_w,
				layer = -1,
			})
			ammo_bg:set_left(mag_bg:right() + (equipped and self._outer_spacer or 0))
				   
			local icon = panel:bitmap({
				name = "icon",
				blend_mode = "normal",
				visible = false,
				w = h_spaced * 2,
				h = h_spaced,
				layer = 10,
				color = Color.white,
			})
			icon:set_top(in_spacer)
			icon:set_left(self._inner_spacer)
				   
			local size = panel:h() * 0.25
			local silencer_icon = panel:bitmap({
				name = "silencer_icon",
				texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
				blend_mode = "normal",
				visible = false,
				w = size,
				h = size,
				layer = 11,
			})
			silencer_icon:set_bottom(icon:bottom())
			silencer_icon:set_right(icon:right())
				   
			--local ammo_text_width = (panel:h() - icon:w()) * (self._main_player and 0.65 or 1)
			local ammo_text_width = h_spaced
			if h_spaced > self._weapons_panel_ammo_w and not equipped then
				ammo_text_width = self._weapons_panel_ammo_w - (in_spacer * 2)
			end
				   
			local ammo_clip = panel:text({
				name = "ammo_clip",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				w = ammo_text_width, --self._weapons_panel_ammo_w,
				h = ammo_text_width,
				vertical = "center",
				align = "right",
				valign = "center",
				font_size = ammo_text_width * 0.9,
				font = tweak_data.hud_players.ammo_font,
				visible = self._main_player
			})
			ammo_clip:set_top(mag_bg:top() + self._inner_spacer)
			ammo_clip:set_right(mag_bg:right() - self._inner_spacer)
				   
			local ammo_total = panel:text({
				name = "ammo_total",
				text = "000",
				color = Color.white,
				blend_mode = "normal",
				layer = 1,
				w = self._weapons_panel_ammo_w,
				h = equipped and (h_spaced * 0.50) or h_spaced,
				vertical = "center",
				valign = "center",
				align = self._main_player and "left" or "right",
				font_size = equipped and (h_spaced * 0.60) or h_spaced,
				font = tweak_data.hud_players.ammo_font
			})
			ammo_total:set_top(ammo_bg:top() + in_spacer)
			if self._main_player then 
				ammo_total:set_left(ammo_bg:left() + self._inner_spacer)
			else 
				ammo_total:set_right(ammo_bg:right() - self._inner_spacer)
			end

			if self._main_player then
				local weapon_selection_panel = panel:panel({
					name = "weapon_selection",
					w = ammo_bg:w() - 10,
					h = (panel:h() - 10) * 0.5,
					layer = 5,
					visible = equipped,
				})
			   weapon_selection_panel:set_bottom(ammo_bg:bottom())
			   weapon_selection_panel:set_left(ammo_bg:left() + 5)

				local firemode_single = weapon_selection_panel:bitmap({
					name = "firemode_single",
					texture = "guis/textures/pd2/blackmarket/inv_mod_singlefire",
					--x = 2,
					layer = 11,
					blend_mode = "normal",
					alpha = 1
				})
				
				local firemode_auto = weapon_selection_panel:bitmap({
					name = "firemode_auto",
					texture = "guis/textures/pd2/blackmarket/inv_mod_autofire",
					--x = 2,
					layer = 11,
					blend_mode = "normal",
					alpha = 1
				})

				firemode_single:set_w((weapon_selection_panel:h() * 0.6))
				firemode_single:set_h((weapon_selection_panel:h() * 0.6))

				firemode_single:set_left(0)
				firemode_single:set_bottom(weapon_selection_panel:h() - self._inner_spacer)

				
				firemode_auto:set_w(weapon_selection_panel:h() * 0.6)
				firemode_auto:set_h(weapon_selection_panel:h() * 0.6)

				firemode_auto:set_right(weapon_selection_panel:w())
				firemode_auto:set_bottom(weapon_selection_panel:h() - self._inner_spacer)


			end
			end

		local w = self._weapons_panel_w
		local h = self._weapons_panel_h
		   
		self._weapons_panel = self._player_panel:panel({
			name = "weapons_panel",
			h = h,
			w = w,
		})

		local h_spaced = h - self._outer_spacer
		
		local h_panel = (h_spaced) * (self._main_player and 0.60 or 0.50)
		local primary_weapon_panel = self._weapons_panel:panel({
			name = "primary_weapon_panel",
			h = h_panel,
			w = self._weapons_panel:w(),
		})
		local secondary_weapon_panel = self._weapons_panel:panel({
			name = "secondary_weapon_panel",
			h = h_panel,
			w = self._weapons_panel:w(),
		})
		primary_weapon_panel:set_top(0) 
		secondary_weapon_panel:set_top(0) 
		
		populate_weapon_panel(secondary_weapon_panel, self._main_player)
		populate_weapon_panel(primary_weapon_panel, self._main_player)

		if self._main_player then
			local h_panel = (h_spaced) * 0.40
			local primary_weapon_panel_uneq = self._weapons_panel:panel({
				name = "primary_weapon_panel_uneq",
				h = h_panel,
				w = self._weapons_panel:w(),
			})
			local secondary_weapon_panel_uneq = self._weapons_panel:panel({
				name = "secondary_weapon_panel_uneq",
				h = h_panel,
				w = self._weapons_panel:w(),
				visible = false
			})

			populate_weapon_panel(primary_weapon_panel_uneq, false)
			populate_weapon_panel(secondary_weapon_panel_uneq, false)
			primary_weapon_panel_uneq:set_top(secondary_weapon_panel:bottom() + self._outer_spacer)
			secondary_weapon_panel_uneq:set_top(secondary_weapon_panel:bottom() + self._outer_spacer)
		else
			secondary_weapon_panel:set_top(primary_weapon_panel:bottom() + self._outer_spacer)
		end

		self:recreate_weapon_firemode()
	end

	function HUDTeammate:_create_equipment_panel()
		local width = self._equipment_panel_w
		local height = self._equipment_panel_h
		   
		self._equipment_panel = self._player_panel:panel({
			name = "equipment_panel",
			h = height,
			w = width,
		})

		--if self._main_player then
			local bg = self._equipment_panel:rect({
				name = "bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = self._bg_opacity,
				h = self._equipment_panel:h(),
				w = self._equipment_panel:w(),
				layer = -1,
			})
		--end
		   
		--local item_panel_height = self._main_player and ((height - 10) / 3) or height
		local item_panel_height = (height - (self._inner_spacer * 2)) / 3
		--local item_panel_width = self._main_player and (width - 10) or (width / 3)
		local item_panel_width = (width - (self._inner_spacer * 2))
		   
			for i, name in ipairs({ "deployable_equipment_panel", "cable_ties_panel", "grenades_panel" }) do
					local panel = self._equipment_panel:panel({
							name = name,
							h = item_panel_height,
							w = item_panel_width,
							visible = false,
					})
				   
					local icon = panel:bitmap({
							name = "icon",
							layer = 1,
							color = Color.white,
							w = panel:h(),
							h = panel:h(),
							layer = 2,
					})
				   
					local amount = panel:text({
							name = "amount",
							text = "00",
							font = "fonts/font_medium_mf",
							font_size = panel:h(),
							color = Color.white,
							align = "right",
							vertical = "center",
							layer = 2,
							w = panel:w(),
							h = panel:h()
					})
				   
					--if self._main_player then
							panel:set_top(((i-1) * (panel:h())) + self._inner_spacer)
							panel:set_left(self._inner_spacer)
					--else
					--		panel:set_left((i-1) * panel:w())
					--end
			end
	end

	function HUDTeammate:_create_name_panel()
		local width = self:w()
		local height = self._name_panel_h
	   
		self._name_panel = self._player_panel:panel({
				name = "name_panel",
				h = height,
				w = width,
		})
	   
--texture = "guis/textures/pd2/hud_tabs",
				--texture_rect = { 84, 34, 19, 19 },

		local callsign = self._name_panel:bitmap({
				name = "callsign",
				texture = self._callsign_txt,
				texture_rect = self._callsign_txt_rect,
				layer = 1,
				color = Color.white,
				blend_mode = "normal",
				w = self._name_panel:h(),
				h = self._name_panel:h()
		})
	   
		local name_sub_panel = self._name_panel:panel({
				name = "name_sub_panel",
				h = self._name_panel:h(),
				w = self._name_panel:w() - callsign:w(),
		})
		name_sub_panel:set_right(self._name_panel:w())
	   
		local text = name_sub_panel:text({
				name = "name",
				text = tostring(self._id),
				layer = 1,
				color = Color.white,
				--align = "left",
				align = "center",
				vertical = "top",
				w = name_sub_panel:w(),
				h = name_sub_panel:h(),
				font_size = name_sub_panel:h() * 0.80,
				font = tweak_data.hud_players.name_font
		})
		--text:set_left(callsign:right())
	end

	function HUDTeammate:_create_special_equipment_panel()
		local width = self._main_player and self:w() or self._health_panel_w
		local height = self._main_player and self._special_equipment_panel_h or self._health_panel_h

		self._special_equipment_panel = self._player_panel:panel({
				name = "special_equipment_panel",
				h = height,
				w = width,
		})

	end

	function HUDManager:add_mugshot(data)
		local peer = managers.network:session():peer(data.peer_id)
		local name = data.name
		if peer then
			name = ProHUD:peerRankName(peer)
		end
		local panel_id = self:add_teammate_panel(data.character_name_id, name, not data.use_lifebar, data.peer_id)
		managers.criminals:character_data_by_name(data.character_name_id).panel_id = panel_id
		local last_id = self._hud.mugshots[#self._hud.mugshots] and self._hud.mugshots[#self._hud.mugshots].id or 0
		local id = last_id + 1
		table.insert(self._hud.mugshots, {
			id = id,
			character_name_id = data.character_name_id,
			peer_id = data.peer_id
		})
		return id
	end

	function HUDTeammate:set_health(data)
			local radial_health = self._health_panel:child("radial_health")
			local red = data.current / data.total
			if red < radial_health:color().red then
					self:_damage_taken()
			end
			radial_health:set_color(Color(1, red, 1, 1))
	end

	function HUDTeammate:set_armor(data)
			local radial_shield = self._health_panel:child("radial_shield")
			local red = data.current / data.total
			if red < radial_shield:color().red then
					self:_damage_taken()
			end
			radial_shield:set_color(Color(1, red, 1, 1))
	end

	function HUDTeammate:_damage_taken()
			local damage_indicator = self._health_panel:child("damage_indicator")
			damage_indicator:stop()
			damage_indicator:animate(callback(self, self, "_animate_damage_taken"))
	end

	function HUDTeammate:set_condition(icon_data, text)
			if icon_data == "mugshot_normal" then
					self._condition_icon:set_visible(false)
			else
					self._condition_icon:set_visible(true)
					local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
					self._condition_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
			end
	end

	function HUDTeammate:set_custom_radial(data)
			local radial_custom = self._health_panel:child("radial_custom")
			local red = data.current / data.total
			radial_custom:set_color(Color(1, red, 1, 1))
			radial_custom:set_visible(red > 0)
	end

	function HUDTeammate:start_timer(time)
			self._timer_paused = 0
			self._timer = time
			self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
			self._condition_timer:set_color(Color.white)
			self._condition_timer:stop()
			self._condition_timer:set_visible(true)
			self._condition_timer:animate(callback(self, self, "_animate_timer"))
	end

	function HUDTeammate:stop_timer()
			if alive(self._player_panel) then
					self._condition_timer:set_visible(false)
					self._condition_timer:stop()
			end
	end

	function HUDTeammate:set_pause_timer(pause)
			if not alive(self._player_panel) then
					return
			end
			--self._condition_timer:set_visible(false)
			self._condition_timer:stop()
	end

	function HUDTeammate:is_timer_running()
			return self._condition_timer:visible()
	end

	function HUDTeammate:_create_stamina_panel(width, height, scale)
			scale = scale or 1
			width = width * scale
			height = height * scale

			self._stamina_panel = self._player_panel:panel({
					name = "stamina_panel",
					h = height,
					w = width,
			})
		   
			local stamina_bar_outline = self._stamina_panel:bitmap({
					name = "stamina_bar_outline",
					texture = "guis/textures/hud_icons",
					texture_rect = { 252, 240, 12, 48 },
					color = Color.white,
					w = width,
					h = height,
					layer = 10,
			})
		   
			local bar_bg = self._stamina_panel:rect({
					name = "bar_bg",
					blend_mode = "normal",
					color = Color.black,
					alpha = 0.5,
					w = width,
					h = height,
					layer = 0,
			})
		   
			self._stamina_bar_max_h = stamina_bar_outline:h() * 0.96
			self._default_stamina_color = Color(0.7, 0.8, 1.0)
		   
			local stamina_bar = self._stamina_panel:rect({
					name = "stamina_bar",
					blend_mode = "normal",
					color = self._default_stamina_color,
					alpha = 0.75,
					h = self._stamina_bar_max_h,
					w = stamina_bar_outline:w() * 0.9,
					layer = 5,
			})
			stamina_bar:set_center(stamina_bar_outline:center())
		   
			local stamina_threshold = self._stamina_panel:rect({
					name = "stamina_threshold",
					color = Color.red,
					w = stamina_bar:w(),
					h = 2,
					layer = 8,
			})
			stamina_threshold:set_center(stamina_bar:center())
	end

	function HUDTeammate:set_max_stamina(value)
			if value ~= self._max_stamina then
					self._max_stamina = value
					local stamina_bar = self._stamina_panel:child("stamina_bar")
				   
					local offset = stamina_bar:h() * (tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD / self._max_stamina)
					self._stamina_panel:child("stamina_threshold"):set_bottom(stamina_bar:bottom() - offset + 1)
			end
	end

	function HUDTeammate:set_current_stamina(value)
			local stamina_bar = self._stamina_panel:child("stamina_bar")
			local stamina_bar_outline = self._stamina_panel:child("stamina_bar_outline")
		   
			stamina_bar:set_h(self._stamina_bar_max_h * (value / self._max_stamina))
			stamina_bar:set_bottom(0.5 * (stamina_bar_outline:h() + self._stamina_bar_max_h))
			if value <= tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and not self._animating_low_stamina then
					self._animating_low_stamina = true
					stamina_bar:animate(callback(self, self, "_animate_low_stamina"), stamina_bar_outline)
			elseif value > tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and self._animating_low_stamina then
					self._animating_low_stamina = nil
			end
	end

	function HUDTeammate:recreate_weapon_firemode()
			if self._main_player then
					local weapon = managers.blackmarket:equipped_primary()
					local panel = self._weapons_panel:child("primary_weapon_panel")
					self:_create_weapon_firemode(weapon, panel, 2)
				   
					weapon = managers.blackmarket:equipped_secondary()
					panel = self._weapons_panel:child("secondary_weapon_panel")
					self:_create_weapon_firemode(weapon, panel, 1)
			end
	end

	function HUDTeammate:_create_weapon_firemode(weapon, panel, id)        
			local weapon_tweak_data = tweak_data.weapon[weapon.weapon_id]
			local fire_mode = weapon_tweak_data.FIRE_MODE
			local can_toggle_firemode = weapon_tweak_data.CAN_TOGGLE_FIREMODE
			local locked_to_auto = managers.weapon_factory:has_perk("fire_mode_auto", weapon.factory_id, weapon.blueprint)
			local locked_to_single = managers.weapon_factory:has_perk("fire_mode_single", weapon.factory_id, weapon.blueprint)

			local has_single = (fire_mode == "single" or can_toggle_firemode) and not locked_to_auto and true or false
			local has_auto = (fire_mode == "auto" or can_toggle_firemode) and not locked_to_single and true or false

			local selection_panel = panel:child("weapon_selection")
			local single_fire = selection_panel:child("firemode_single")
			local auto_fire = selection_panel:child("firemode_auto")
		   
			single_fire:set_color(has_single and Color.white or Color(0.6, 0.1, 0.1))
			auto_fire:set_color(has_auto and Color.white or Color(0.6, 0.1, 0.1))
		   
			local default = locked_to_auto and "auto" or locked_to_single and "single" or fire_mode
			self:set_weapon_firemode(id, default)
	end

	function HUDTeammate:set_weapon_selected(id, hud_icon)
		if self._main_player then
			-- id = 1 secondary weapon
			self._weapons_panel:child("primary_weapon_panel"):set_visible(id ~= 1)
			self._weapons_panel:child("secondary_weapon_panel"):set_visible(id == 1)

			if self._main_player then 
				self._weapons_panel:child("primary_weapon_panel_uneq"):set_visible(id == 1)
				self._weapons_panel:child("secondary_weapon_panel_uneq"):set_visible(id ~= 1)
			end
		end
	end

	function HUDTeammate:set_weapon_firemode(id, firemode)
			local panel = self._weapons_panel:child(id == 1 and "secondary_weapon_panel" or "primary_weapon_panel")
			local selection_panel = panel:child("weapon_selection")
			local single_fire = selection_panel:child("firemode_single")
			local auto_fire = selection_panel:child("firemode_auto")
		   
			local active_alpha = 1
			local inactive_alpha = 0.55
		   
			if firemode == "single" then
					auto_fire:set_alpha(inactive_alpha)
					--auto_fire:set_color(Color(0.6, 0.1, 0.1))
					single_fire:set_alpha(active_alpha)
					--single_fire:set_color(Color.black)
			elseif firemode == "auto" then
				   auto_fire:set_alpha(active_alpha)
				   -- auto_fire:set_color(Color.black)
				   single_fire:set_alpha(inactive_alpha)
				   -- single_fire:set_color(Color(0.6, 0.1, 0.1))
			end
	end

	function HUDTeammate:set_weapon_id(slot, id, silencer)
			local bundle_folder = tweak_data.weapon[id] and tweak_data.weapon[id].texture_bundle_folder
			local guis_catalog = "guis/"
			if bundle_folder then
					guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
			end
			local texture_name = tweak_data.weapon[id] and tweak_data.weapon[id].texture_name or tostring(id)
			local bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/weapons/" .. texture_name

			local panel = self._weapons_panel:child(slot == 1 and "secondary_weapon_panel" or "primary_weapon_panel")
			local icon = panel:child("icon")
			local silencer_icon = panel:child("silencer_icon")
			icon:set_visible(true)
			icon:set_image(bitmap_texture)
			silencer_icon:set_visible(silencer)

			if self._main_player then
				local panel = self._weapons_panel:child(slot == 1 and "secondary_weapon_panel_uneq" or "primary_weapon_panel_uneq")
				local icon = panel:child("icon")
				icon:set_visible(true)
				icon:set_image(bitmap_texture)
				silencer_icon:set_visible(silencer)
			end
	end

	function HUDTeammate:set_ammo_amount_by_type(type, max_clip, current_clip, current_left, max)
			local low_ammo = current_left <= math.round(max_clip / 2)
			local low_ammo_clip = current_clip <= math.round(max_clip / 4)
			local out_of_ammo_clip = current_clip <= 0
			local out_of_ammo = current_left <= 0
			local color_total = out_of_ammo and Color(1, 0.9, 0.3, 0.3)
			color_total = color_total or low_ammo and Color(1, 0.9, 0.9, 0.3)
			color_total = color_total or Color.white
			local color_clip = out_of_ammo_clip and Color(1, 0.9, 0.3, 0.3)
			color_clip = color_clip or low_ammo_clip and Color(1, 0.9, 0.9, 0.3)
			color_clip = color_clip or Color.white
		   
			local panel = self._weapons_panel:child(type .. "_weapon_panel")
			local ammo_clip = panel:child("ammo_clip")
			local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
			ammo_clip:set_text(zero .. tostring(current_clip))
			ammo_clip:set_color(color_clip)
			ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
		   
			local ammo_total = panel:child("ammo_total")
			local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
			ammo_total:set_text(zero .. tostring(current_left))
			ammo_total:set_color(color_total)
			ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))

			-- do the same for unequipped type
			if self._main_player then
				local panel = self._weapons_panel:child(type .. "_weapon_panel_uneq")
				local ammo_clip = panel:child("ammo_clip")
				local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
				ammo_clip:set_text(zero .. tostring(current_clip))
				ammo_clip:set_color(color_clip)
				ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
			   
				local ammo_total = panel:child("ammo_total")
				local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
				ammo_total:set_text(zero .. tostring(current_left))
				ammo_total:set_color(color_total)
				ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))
			end
	end

	function HUDTeammate:_set_amount_string(text, amount)
			local zero = self._main_player and amount < 10 and "0" or ""
			text:set_text(zero .. amount)
			text:set_range_color(0, string.len(zero), Color.white:with_alpha(0.5))
	end

	function HUDTeammate:set_deployable_equipment(data)
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
			local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
			local deployable_icon = deployable_equipment_panel:child("icon")
			deployable_icon:set_image(icon, unpack(texture_rect))
			self:set_deployable_equipment_amount(1, data)
	end

	function HUDTeammate:set_deployable_equipment_amount(index, data)
			local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
			local deployable_amount = deployable_equipment_panel:child("amount")
			self:_set_amount_string(deployable_amount, data.amount)
			deployable_equipment_panel:set_visible(data.amount ~= 0)
	end

	function HUDTeammate:set_cable_tie(data)
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
			local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
			local tie_icon = cable_ties_panel:child("icon")
			tie_icon:set_image(icon, unpack(texture_rect))
			self:set_cable_ties_amount(data.amount)
	end

	function HUDTeammate:set_cable_ties_amount(amount)
			local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
			self:_set_amount_string(cable_ties_panel:child("amount"), amount)
			cable_ties_panel:set_visible(amount ~= 0)
	end

	function HUDTeammate:set_grenades(data)
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
			local grenades_panel = self._equipment_panel:child("grenades_panel")
			local grenade_icon = grenades_panel:child("icon")
			grenade_icon:set_image(icon, unpack(texture_rect))
			self:set_grenades_amount(data)
	end

	function HUDTeammate:set_grenades_amount(data)
			local grenades_panel = self._equipment_panel:child("grenades_panel")
			local amount = grenades_panel:child("amount")
			self:_set_amount_string(amount, data.amount)
			grenades_panel:set_visible(data.amount ~= 0)
	end

	function HUDTeammate:add_special_equipment(data)
			local h = self._main_player and self._special_equipment_panel:h() or self._special_equipment_panel:h() / 3 --(self._main_player and 4 or 3)
			--local w = self._main_player and self._special_equipment_panel:h() or h --(self._main_player and 4 or 3)
		   
			local equipment_panel = self._special_equipment_panel:panel({
					name = data.id,
					h = h,
					w = h,
			})
			table.insert(self._special_equipment, equipment_panel)
		   
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
			local bitmap = equipment_panel:bitmap({
					name = "bitmap",
					texture = icon,
					color = Color.white,
					layer = 1,
					texture_rect = texture_rect,
					w = equipment_panel:w(),
					h = equipment_panel:h()
			})
		   
			local amount, amount_bg
			if data.amount then
					amount = equipment_panel:child("amount") or equipment_panel:text({
							name = "amount",
							text = tostring(data.amount),
							font = "fonts/font_small_noshadow_mf",
							font_size = 12 * equipment_panel:h() / 32,
							color = Color.black,
							align = "center",
							vertical = "center",
							layer = 4,
							w = equipment_panel:w(),
							h = equipment_panel:h()
					})
					amount:set_visible(1 < data.amount)
					amount_bg = equipment_panel:child("amount_bg") or equipment_panel:bitmap({
							name = "amount_bg",
							texture = "guis/textures/pd2/equip_count",
							color = Color.white,
							layer = 3,
					})
					amount_bg:set_size(amount_bg:w() * equipment_panel:w() / 32, amount_bg:h() * equipment_panel:h() / 32)
					amount_bg:set_center(bitmap:center())
					amount_bg:move(amount:w() * 0.2, amount:h() * 0.2)
					amount_bg:set_visible(1 < data.amount)
					amount:set_center(amount_bg:center())
			end
		   
			local flash_icon = equipment_panel:bitmap({
					name = "bitmap",
					texture = icon,
					color = tweak_data.hud.prime_color,
					layer = 2,
					texture_rect = texture_rect,
					w = equipment_panel:w() + 2,
					h = equipment_panel:w() + 2
			})
		   
			local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
			flash_icon:set_center(bitmap:center())
			flash_icon:animate(hud.flash_icon, nil, equipment_panel)
			self:layout_special_equipments()
	end

	function HUDTeammate:remove_special_equipment(equipment)
			for i, panel in ipairs(self._special_equipment) do
					if panel:name() == equipment then
							local data = table.remove(self._special_equipment, i)
							self._special_equipment_panel:remove(panel)
							self:layout_special_equipments()
							return
					end
			end
	end

	function HUDTeammate:set_special_equipment_amount(equipment_id, amount)
			for i, panel in ipairs(self._special_equipment) do
					if panel:name() == equipment_id then
							panel:child("amount"):set_text(tostring(amount))
							panel:child("amount"):set_visible(amount > 1)
							panel:child("amount_bg"):set_visible(amount > 1)
							return
					end
			end
	end

	function HUDTeammate:clear_special_equipment()
			self:remove_panel()
			self:add_panel()
	end

	function HUDTeammate:layout_special_equipments()
			if #self._special_equipment > 0 then
					local h = self._special_equipment[1]:h()
					local w = self._special_equipment[1]:w()
					
					local items_per_column = math.floor(self._special_equipment_panel:w() / (self._main_player and 9 or 3))
				   
					for i, panel in ipairs(self._special_equipment) do
							if self._main_player then
								panel:set_top(0)
								panel:set_right(self._special_equipment_panel:right() - ((i-1) * w))
							else
								local column = math.floor((i-1) / items_per_column)
								panel:set_left(0 + column * w)
								panel:set_top(0 + (i - 1 - column * items_per_column) * h)
							end
					end
			end
	end

	function HUDTeammate:_create_carry_panel()
			local width = self:w()
			local height = self._carry_panel_h
		   
			self._carry_panel = self._player_panel:panel({
					name = "carry_panel",
					visible = false,
					h = height,
					w = width,
					align = self._main_player and "right" or "left"
			})
		   
			local text = self._carry_panel:text({
					name = "text",
					layer = 1,
					color = Color.white,
					w = self._carry_panel:w(),
					h = self._carry_panel:h(),
					vertical = "center",
					align = self._main_player and "right" or "left",
					font_size = self._carry_panel:h(),
					font = tweak_data.hud.medium_font_noshadow,
			})
		   
			local icon = self._carry_panel:bitmap({
					name = "icon",
					visible = false,        --Shows otherwise for some reason...
					texture = "guis/textures/pd2/hud_tabs",
					texture_rect = { 32, 33, 32, 31 },
					w = self._carry_panel:h(),
					h = self._carry_panel:h(),
					layer = 1,
					color = Color.white,
			})
	  
			self:remove_carry_info()
	end

	function HUDTeammate:set_carry_info(carry_id, value)
			local name_id = carry_id and tweak_data.carry[carry_id] and tweak_data.carry[carry_id].name_id
			local carry_text = utf8.to_upper(name_id and managers.localization:text(name_id) or "UNKNOWN")
			local text = self._carry_panel:child("text")
			local icon = self._carry_panel:child("icon")
		   
			text:set_text(carry_text)
			local _, _, w, _ = text:text_rect()
			text:set_w(w)
			text:set_right(self._carry_panel:w())
			icon:set_right(text:left() - 5)
			icon:set_visible(true)

			if not self._main_player then
				icon:set_left(0)
				text:set_left(icon:right() + 5)
			end
		   
			self._carry_panel:set_visible(true)
			self._carry_panel:animate(callback(self, self, "_animate_carry_pickup"))
	end

	function HUDTeammate:remove_carry_info()
			self._carry_panel:stop()
			self._carry_panel:set_visible(false)
	end

	function HUDTeammate:get_carry_panel_info()
			return self._carry_panel:w(), self._carry_panel:h(), self._parent:w() - self._carry_panel:w(), (self._parent:h() - self._player_panel:h() - (self._carry_panel:h() * 2))
	end

	function HUDTeammate:_create_kills_panel(width, height, scale)
			local scale = self._scale or 1
			local width = 40 * scale
			local height = 25 * scale
		   
			self._kills_panel = self._panel:panel({
					name = "kills_panel",
					visible = HUDManager._USE_KILL_COUNTER,
					h = height,
					w = width,
			})
		   
			local icon = self._kills_panel:bitmap({
					name = "icon",
					texture = "guis/textures/pd2/cn_miniskull",
					w = self._kills_panel:h() * 0.75,
					h = self._kills_panel:h(),
					texture_rect = { 0, 0, 12, 16 },
					alpha = 1,
					visible = false, --HUDManager._USE_KILL_COUNTER,
					blend_mode = "add",
					color = Color.yellow
			})
		   
			local text = self._kills_panel:text({
					name = "text",
					text = "0 / 0",
					layer = 1,
					visible = HUDManager._USE_KILL_COUNTER,
					color = Color.yellow,
					w = self._kills_panel:w() - icon:w() - 1,
					h = self._kills_panel:h(),
					vertical = "center",
					align = "left",
					font_size = self._kills_panel:h(),
					font = tweak_data.hud_players.name_font
			})
			text:set_right(self._kills_panel:w())
	end

	function HUDTeammate:increment_kill_count(is_special, headshot)
			self._kill_count = self._kill_count + 1
			self._kill_count_special = self._kill_count_special + (is_special and 1 or 0)
			self._headshot_kills = self._headshot_kills + (headshot and 1 or 0)
			self:_update_kill_count_text()
	end

	function HUDTeammate:_update_kill_count_text()
			local text = tostring(self._kill_count)
			if HUDTeammate.SHOW_SPECIAL_KILLS then
					text = text .. "/" .. tostring(self._kill_count_special)
			end
			if HUDTeammate.SHOW_HEADSHOT_KILLS then
					text = text .. " (" .. tostring(self._headshot_kills) .. ")"
			end
		   
			local field = self._kills_panel:child("text")
			field:set_text(text)
	end

	function HUDTeammate:reset_kill_count()
			self._kill_count = 0
			self._kill_count_special = 0
			self._headshot_kills = 0
			self:_update_kill_count_text()
	end

	function HUDTeammate:set_cheater(state)
			--if not self._main_player then
					self._name_panel:child("name_sub_panel"):child("name"):set_color(state and tweak_data.screen_colors.pro_color or Color.white)
			--end
	end

	function HUDTeammate:set_name(teammate_name)
			--if not self._main_player and self._name ~= teammate_name then
					self._name = teammate_name
					self:reset_kill_count()
					self._name_panel:stop()
				   
					local sub_panel = self._name_panel:child("name_sub_panel")
					local text = sub_panel:child("name")
					text:set_left(0)
					text:set_text(utf8.to_upper(teammate_name))
					local _, _, w, _ = text:text_rect()
					w = w + 5
					text:set_w(w)
					if w > sub_panel:w() then
							self._name_panel:animate(callback(self, self, "_animate_name_label"), w - sub_panel:w())
					end
			--end
	end

	function HUDTeammate:set_callsign(id)
		   -- if not self._main_player then
					self._name_panel:child("name_sub_panel"):child("name"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
					self._name_panel:child("callsign"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
					self:set_voice_com(false)
		  --  end
	end

	function HUDTeammate:set_voice_com(status)
		if not self._ai then
			local texture = status and "guis/textures/pd2/jukebox_playing" or self._callsign_txt
			local texture_rect = status and { 0, 0, 16, 16 } or self._callsign_txt_rect

			local callsign = self._name_panel:child("callsign")
			callsign:set_image(texture, unpack(texture_rect))
			if status then
					callsign:animate(callback(self, self, "_animate_voice_com"), self._name_panel:h(), callsign:center())
			else
					callsign:stop()
					callsign:set_size(self._name_panel:h(), self._name_panel:h())
					callsign:set_position(0, 0)
			end
		end
	end

	function HUDTeammate:_create_latency_panel()
			local scale = self._scale or 1
			local width = 35 * scale
			local height = 25 * scale
		   
			self._latency_panel = self._player_panel:panel({
					name = "latency_panel",
					h = height,
					w = width,
			})
		   
			local text = self._latency_panel:text({
					name = "text",
					text = "0",
					layer = 1,
					color = Color.yellow,
					w = self._latency_panel:w(),
					h = self._latency_panel:h(),
					vertical = "center",
					align = "center",
					font_size = self._latency_panel:h() * 0.7,
					font = tweak_data.hud_players.name_font
			})
	end

	function HUDTeammate:update_latency(value)
			if not (self._ai or self._main_player) then
					self._latency_panel:set_visible(true)
					local text = self._latency_panel:child("text")
					text:set_text(string.format("%d", value))
					text:set_color(value < 75 and Color.green or value < 150 and Color.yellow or Color.red)
			end
	end

	function HUDTeammate:_create_interact_panel_new()
			self._interact_panel = self._player_panel:panel({
					name = "interact_panel",
					layer = 0,
					visible = false,
					w = self._weapons_panel:w(),
					h = self._weapons_panel:h(),
			})
		   

		   	local bg = self._interact_panel:rect({
				name = "interact_panel_bg",
				blend_mode = "normal",
				color = Color.black,
				alpha = self._bg_opacity,
				h = self._interact_panel:h(),
				w = self._interact_panel:w(),
				layer = -1,
			})
			--HUDBGBox_create(self._interact_panel, {
			--				w = self._interact_panel:w(),
			--				h = self._interact_panel:h(),
			--		}, {})
		   
			local interact_text = self._interact_panel:text({
					name = "interact_text",
					layer = 10,
					color = Color.white,
					w = self._interact_panel:w(),
					h = self._interact_panel:h() * 0.5,
					vertical = "center",
					align = "center",
					blend_mode = "normal",
					font_size = (self._interact_panel:h() * 0.5) * 0.4,
					font = tweak_data.hud_players.name_font
			})
			interact_text:set_top(0)
		   
			local interact_bar_outline = self._interact_panel:bitmap({
					texture = "guis/textures/hud_icons",
					texture_rect = { 252, 240, 12, 48 },
					w = self._interact_panel:h() * 0.5,
					h = self._interact_panel:w() * 0.75,
					layer = 10,
					rotation = 90
			})
			interact_bar_outline:set_center(self._interact_panel:w() / 2, 0)
			interact_bar_outline:set_bottom(self._interact_panel:h() + interact_bar_outline:h() / 2 - interact_bar_outline:w() / 2)
		   
			self._interact_bar_max_width = interact_bar_outline:h() * 0.97
		   
			local interact_bar = self._interact_panel:rect({
					name = "interact_bar",
					blend_mode = "normal",
					color = Color(0.7, 0.7, 0.7),
					alpha = 0.75,
					h = interact_bar_outline:w() * 0.8,
					w = self._interact_bar_max_width,
					layer = 5,
			})
			interact_bar:set_center(interact_bar_outline:center())
		   
			local interact_bar_bg = self._interact_panel:rect({
					name = "interact_bar_bg",
					blend_mode = "normal",
					color = Color.black,
					alpha = 1.0,
					h = interact_bar_outline:w(),
					w = interact_bar_outline:h(),
					layer = 0,
			})
			interact_bar_bg:set_center(interact_bar:center())
		   
			local interact_timer = self._interact_panel:text({
					name = "interact_timer",
					layer = 10,
					color = Color.white,
					w = interact_bar:w(),
					h = interact_bar:h(),
					vertical = "center",
					align = "center",
					blend_mode = "normal",
					font_size = interact_bar:h() * 0.8,
					font = tweak_data.hud_players.name_font
			})
			interact_timer:set_center(interact_bar:center())
	end

	function HUDTeammate:teammate_progress(enabled, tweak_data_id, timer, success)
			debug_check_tweak_data(tweak_data_id)
		   
			--if not self._main_player then
					self._interact_panel:stop()
				   
					if not enabled or success then
							self._interact_panel:set_visible(false)
							self._weapons_panel:set_visible(true)
					end
				   
					if enabled and timer > 1 then
							self._interact_panel:set_visible(true)
							self._weapons_panel:set_visible(false)
						   
							local text = ""
							if tweak_data_id then
									local action_text_id = tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].action_text_id or "hud_action_generic"
									text = HUDTeammate._INTERACTION_TEXTS[tweak_data_id] or action_text_id and managers.localization:text(action_text_id)
							end
						   
							--self._interact_panel:child("interact_text"):set_text(string.format("%s (%.1fs)", utf8.to_upper(text), timer))
							self._interact_panel:child("interact_text"):set_text(string.format("%s", utf8.to_upper(text)))
							self._interact_panel:animate(callback(self, self, "_animate_interact_timer_new"), timer)
					end
			--end
	end

	function HUDTeammate:panel()
			return self._panel
	end

	function HUDTeammate:peer_id()
			return self._peer_id
	end

	function HUDTeammate:add_panel()
			self._panel:set_visible(true)
	end

	function HUDTeammate:remove_panel()
			while self._special_equipment[1] do
					self._special_equipment_panel:remove(table.remove(self._special_equipment, 1))
			end
		   
			--self._weapons_panel:child("secondary_weapon_panel"):child("icon"):set_visible(false)
			--self._weapons_panel:child("primary_weapon_panel"):child("icon"):set_visible(false)
			self._panel:set_visible(false)
			self:set_condition("mugshot_normal")
			self:set_cheater(false)
			self:stop_timer()
			self:set_peer_id(nil)
			self:set_ai(nil)
			self:teammate_progress(false)
			self:remove_carry_info()
	end

	function HUDTeammate:set_peer_id(peer_id)
			self._peer_id = peer_id

			local peer = peer_id and managers.network:session():peer(peer_id)
			if peer then
					local outfit = peer:blackmarket_outfit()
				   
					for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
							local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
							local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
							self:set_weapon_id(selection, weapon_id, silencer)
					end
			end
	end

	function HUDTeammate:set_ai(ai)
			self._ai = ai
		   
			self._weapons_panel:set_visible(not ai and true or false)
			self._equipment_panel:set_visible(not ai and true or false)
			self._special_equipment_panel:set_visible(not ai and true or false)
			self._equipment_panel:set_visible(not ai and true or false)
			self._carry_panel:set_visible(not ai and true or false)

			-- ai call sign
			if ai then
				local texture = "guis/textures/pd2/cn_minighost"
				local texture_rect = { 0, 0, 16, 16 }

				local callsign = self._name_panel:child("callsign")
				callsign:set_image(texture, unpack(texture_rect))
			end

			if not HUDTeammate.SHOW_AI_KILLS then
					self._kills_panel:set_visible(not ai and true or false)
			end
		   
			if not self._main_player then
					self._latency_panel:set_visible(not ai and true or false)
					if ai then
							self._interact_panel:set_visible(false)
					end
					self._name_panel:child("name_sub_panel"):child("name"):set_color((not ai and tweak_data.chat_colors[self._id] or Color.white):with_alpha(1))
			end
	end

	function HUDTeammate:set_state(state)
			--log_print("out.log", string.format("HUDTeammate:set_state(%s)\n", tostring(state)))
	end

	function HUDTeammate:_animate_damage_taken(damage_indicator)
			damage_indicator:set_alpha(1)
			local st = 3
			local t = st
			local st_red_t = 0.5
			local red_t = st_red_t
			while t > 0 do
					local dt = coroutine.yield()
					t = t - dt
					red_t = math.clamp(red_t - dt, 0, 1)
					damage_indicator:set_color(Color(1, red_t / st_red_t, red_t / st_red_t))
					damage_indicator:set_alpha(t / st)
			end
			damage_indicator:set_alpha(0)
	end

	function HUDTeammate:_animate_timer()
			local rounded_timer = math.round(self._timer)
			while self._timer >= 0 do
					local dt = coroutine.yield()
					if self._timer_paused == 0 then
							self._timer = self._timer - dt
							local text = self._timer < 0 and "00" or (math.round(self._timer) < 10 and "0" or "") .. math.round(self._timer)
							self._condition_timer:set_text(text)
							if rounded_timer > math.round(self._timer) then
									rounded_timer = math.round(self._timer)
									if rounded_timer < 11 then
											self._condition_timer:animate(callback(self, self, "_animate_timer_flash"))
									end
							end
					end
			end
	end

	function HUDTeammate:_animate_timer_flash()
			local t = 0
			while t < 0.5 do
					t = t + coroutine.yield()
					local n = 1 - math.sin(t * 180)
					local r = math.lerp(1 or self._point_of_no_return_color.r, 1, n)
					local g = math.lerp(0 or self._point_of_no_return_color.g, 0.8, n)
					local b = math.lerp(0 or self._point_of_no_return_color.b, 0.2, n)
					self._condition_timer:set_color(Color(r, g, b))
					self._condition_timer:set_font_size(math.lerp(self._health_panel:h() * 0.5, self._health_panel:h() * 0.8, n))
			end
			self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
	end

	function HUDTeammate:_animate_voice_com(callsign, original_size, cx, cy)
			local t = 0
		   
			while true do
					local dt = coroutine.yield()
					t = t + dt
				   
					local size = (math.sin(t * 360) * 0.15 + 1) * original_size
					callsign:set_size(size, size)
					callsign:set_center(cx, cy)
			end
	end

	function HUDTeammate:_animate_carry_pickup(carry_panel)
			local DURATION = 2
			local text = self._carry_panel:child("text")
			local icon = self._carry_panel:child("icon")
		   
			local t = DURATION
			while t > 0 do
					local dt = coroutine.yield()
					t = math.max(t-dt, 0)
				   
					local r = math.sin(720 * t) * 0.5 + 0.5
					text:set_color(Color(1, 1, 1, r))
					icon:set_color(Color(1, 1, 1, r))
			end
		   
			text:set_color(Color(1, 1, 1, 1))
			icon:set_color(Color(1, 1, 1, 1))
	end

	function HUDTeammate:_animate_interact_timer_new(panel, timer)
			local color_table = {
					{ ratio = 0.0, color = Color(1, 0.9, 0.1, 0.1) }, --Red
					{ ratio = 0.5, color = Color(1, 0.9, 0.9, 0.1) }, --Yellow
					{ ratio = 1.0, color = Color(1, 0.1, 0.9, 0.1) } --Green
			}
			local t = 0
			local current_color = color_table[#color_table].color
		   
			local bar = panel:child("interact_bar")
			local text = panel:child("interact_timer")
		   
			bar:set_w(0)
			text:set_text("")
		   
			while timer > t do
					t = math.min(t + coroutine.yield(), timer)
					local time_left = timer - t
					local ratio = 1 - time_left / timer

					for i, data in ipairs(color_table) do
							if ratio < data.ratio then
									local nxt = color_table[math.clamp(i-1, 1, #color_table)]
									local scale = (ratio - data.ratio) / (nxt.ratio - data.ratio)
									current_color = Color(
											(data.color.alpha or 1) * (1-scale) + (nxt.color.alpha or 1) * scale,
											(data.color.red or 0) * (1-scale) + (nxt.color.red or 0) * scale,
											(data.color.green or 0) * (1-scale) + (nxt.color.green or 0) * scale,
											(data.color.blue or 0) * (1-scale) + (nxt.color.blue or 0) * scale)
									break
							end
					end

					bar:set_w(ratio * self._interact_bar_max_width)
					bar:set_color(current_color)
					text:set_text(string.format("%.1fs", time_left))
			end
	end

	function HUDTeammate:_animate_low_stamina(stamina_bar, stamina_bar_outline)
			local target = Color(1.0, 0.1, 0.1)
			local bar = self._default_stamina_color
			local border = Color.white

			while self._animating_low_stamina do
					local t = 0
					while t <= 0.5 do
							t = t + coroutine.yield()
							local ratio = 0.5 + 0.5 * math.sin(t * 720)
							stamina_bar:set_color(Color(
									bar.r + (target.r - bar.r) * ratio,
									bar.g + (target.g - bar.g) * ratio,
									bar.b + (target.b - bar.b) * ratio))
							stamina_bar_outline:set_color(Color(
									border.r + (target.r - border.r) * ratio,
									border.g + (target.g - border.g) * ratio,
									border.b + (target.b - border.b) * ratio))
					end
			end
		   
			stamina_bar:set_color(bar)
			stamina_bar_outline:set_color(border)
	end

	function HUDTeammate:_animate_name_label(panel, width)
			local t = 0
			local text = self._name_panel:child("name_sub_panel"):child("name")
		   
			while true do
					t = t + coroutine.yield()
					text:set_left(width * (math.sin(90 + t * HUDTeammate._NAME_ANIMATE_SPEED) * 0.5 - 0.5))
			end
	end
elseif RequiredScript == "lib/managers/hud/hudtemp" then
 
 
        HUDTemp._MARGIN = 8
 
        function HUDTemp:init(hud)
                self._hud_panel = hud.panel
                if self._hud_panel:child("bag_panel") then
                        self._hud_panel:remove(self._hud_panel:child("bag_panel"))
                end
               
                self._destination_size_ratio = 0.5
               
                self._panel = self._hud_panel:panel({
                        visible = false,
                        name = "bag_panel",
                })
               
                self._bg_box = HUDBGBox_create(self._panel, { }, {})
               
                self._bag_icon = self._panel:bitmap({
                        name = "bag_icon",
                        texture = "guis/textures/pd2/hud_tabs",
                        texture_rect = { 32, 33, 32, 31 },
                        visible = true,
                        layer = 0,
                        color = Color.white,
                })
               
                self._carry_text = self._panel:text({
                        name = "carry_text",
                        visible = true,
                        layer = 2,
                        color = Color.white,
                        font = tweak_data.hud.medium_font_noshadow,
                        align = "left",
                        vertical = "center",
                })
        end
 
        function HUDTemp:show_carry_bag(carry_id, value)
                self._carry_id = carry_id
                self._value = value
                local carry_data = tweak_data.carry[carry_id]
                local type_text = carry_data.name_id and managers.localization:text(carry_data.name_id)
               
                self._carry_text:set_text(utf8.to_upper(type_text))
                local width = self:_get_text_width(self._carry_text) + HUDTemp._MARGIN * 2 + self._bag_icon:w()
                self._bg_box:set_w(width)
                self._bag_icon:set_left(self._bg_box:left() + HUDTemp._MARGIN)
                self._carry_text:set_left(self._bag_icon:right())
               
                self._panel:stop()
                local w, h, x, y = managers.hud:get_teammate_carry_panel_info(HUDManager.PLAYER_PANEL)
                self._panel:animate(callback(self, self, "_animate_pickup"), w, h, x, y, h)
        end
 
        function HUDTemp:hide_carry_bag()
                self._carry_id = nil
                self._value = nil
                self._panel:stop()
                self._panel:animate(callback(self, self, "_animate_drop"))
        end
 
        function HUDTemp:_get_text_width(obj)
                local _, _, w, _ = obj:text_rect()
                return w
        end
 
        function HUDTemp:_animate_pickup(o, ew, eh, ex, ey)
                local function update_size(w, h)
                        self._panel:set_size(w * 1.1, h * 2)
                        self._carry_text:set_font_size(h)
                        local text_w = self:_get_text_width(self._carry_text)
                        self._bag_icon:set_size(h, h)
                        self._carry_text:set_size(text_w, h)
                       
                        self._bg_box:set_size(1.3 * (self._carry_text:w() + self._bag_icon:w() * 1.3), h * 1.75)
                        self._bg_box:set_center(self._panel:w() / 2 - self._bg_box:w() * 0.05, self._panel:h() / 2)
                        self._carry_text:set_center(0, self._panel:h() / 2)
                        self._carry_text:set_right(self._panel:w() / 2 + self._carry_text:w() / 2 + self._bag_icon:w() / 4)
                        self._bag_icon:set_center(0, self._panel:h() / 2)
                        self._bag_icon:set_right(self._carry_text:left() - self._bag_icon:w() / 4)
                end
               
                local FLASH_T = 1
                local MOVE_T = 0.2
               
                self._panel:set_visible(true)
                local sw = ew / self._destination_size_ratio
                local sh = eh / self._destination_size_ratio
                update_size(sw, sh)
                self._panel:set_center(self._hud_panel:center())
                self._panel:set_y(self._hud_panel:h() * 0.45)
                local sx = self._panel:x()
                local sy = self._panel:y()
               
                local t = FLASH_T
                while t > 0 do
                        local dt = coroutine.yield()
                        t = math.max(t - dt, 0)
                        local val = math.sin(4 * 360 * t^2)
                        self._panel:set_visible(val > 0)
                end
                self._panel:set_visible(true)
               
                t = MOVE_T
                while t > 0 do
                        local dt = coroutine.yield()
                        t = math.max(t - dt, 0)
                        local ratio = (MOVE_T-t)/MOVE_T
                        local x = math.lerp(sx, ex, ratio)
                        local y = math.lerp(sy, ey, ratio)
                        self._panel:set_position(x, y)
                       
                        local w = math.lerp(sw, ew, ratio)
                        local h = math.lerp(sh, eh, ratio)
                        update_size(w, h)
                end
               
                self._panel:set_visible(false)
                managers.hud:set_teammate_carry_info(HUDManager.PLAYER_PANEL, self._carry_id, self._value, true)
        end
 
        function HUDTemp:_animate_drop(object)
                object:set_visible(false)
        end
 
        function HUDTemp:set_throw_bag_text() end
        function HUDTemp:set_stamina_value(value) end
        function HUDTemp:set_max_stamina(value) end
              
elseif RequiredScript == "lib/managers/hud/hudobjectives" then
       
       
        HUDObjectives._TEXT_MARGIN = 8
 
        function HUDObjectives:init(hud)
                if hud.panel:child("objectives_panel") then
                        hud.panel:remove(self._panel:child("objectives_panel"))
                end
 
                self._panel = hud.panel:panel({
                        visible = false,
                        name = "objectives_panel",
                        h = 100,
                        w = 500,
                        x = 60,
                        valign = "top"
                })
                       
                self._bg_box = HUDBGBox_create(self._panel, {
                        w = 500,
                        h = 38,
                })
               
                self._objective_text = self._bg_box:text({
                        name = "objective_text",
                        visible = false,
                        layer = 2,
                        color = Color.white,
                        text = "",
                        font_size = tweak_data.hud.active_objective_title_font_size,
                        font = tweak_data.hud.medium_font_noshadow,
                        align = "left",
                        vertical = "center",
                        w = self._bg_box:w(),
                        x = HUDObjectives._TEXT_MARGIN
                })
               
                self._amount_text = self._bg_box:text({
                        name = "amount_text",
                        visible = false,
                        layer = 2,
                        color = Color.white,
                        text = "",
                        font_size = tweak_data.hud.active_objective_title_font_size,
                        font = tweak_data.hud.medium_font_noshadow,
                        align = "left",
                        vertical = "center",
                        w = self._bg_box:w(),
                        x = HUDObjectives._TEXT_MARGIN
                })
        end
 
        function HUDObjectives:activate_objective(data)
                self._active_objective_id = data.id
               
                self._panel:set_visible(true)
                self._objective_text:set_text(utf8.to_upper(data.text))
                self._objective_text:set_visible(true)
                self._amount_text:set_visible(false)
               
                local width = self:_get_text_width(self._objective_text)
               
                if data.amount then
                        self:update_amount_objective(data)
                        self._amount_text:set_left(width + HUDObjectives._TEXT_MARGIN)
                        width = width + self:_get_text_width(self._amount_text)
                else
                        self._amount_text:set_text("")
                end
 
                self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + width)
                self._bg_box:stop()
                --self._amount_text:animate(callback(self, self, "_animate_new_objective"))
                --self._objective_text:animate(callback(self, self, "_animate_new_objective"))
                self._bg_box:animate(callback(self, self, "_animate_update_objective"))
        end
 
        function HUDObjectives:update_amount_objective(data)
                if data.id ~= self._active_objective_id then
                        return
                end
 
                self._amount_text:set_visible(true)
                self._amount_text:set_text(": " .. (data.current_amount or 0) .. "/" .. data.amount)
                self._amount_text:set_x(self:_get_text_width(self._objective_text) + HUDObjectives._TEXT_MARGIN)
                self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + self:_get_text_width(self._objective_text) + self:_get_text_width(self._amount_text))
                self._bg_box:stop()
                self._bg_box:animate(callback(self, self, "_animate_update_objective"))
        end
 
        function HUDObjectives:remind_objective(id)
                if id ~= self._active_objective_id then
                        return
                end
               
                self._bg_box:stop()
                self._bg_box:animate(callback(self, self, "_animate_update_objective"))
        end
 
        function HUDObjectives:complete_objective(data)
                if data.id ~= self._active_objective_id then
                        return
                end
 
                self._amount_text:set_visible(false)
                self._objective_text:set_visible(false)
                self._panel:set_visible(false)
                self._bg_box:set_w(0)
        end
 
        function HUDObjectives:_animate_new_objective(object)
                local TOTAL_T = 2
                local t = TOTAL_T
                object:set_color(Color(1, 1, 1, 1))
                while t > 0 do
                        local dt = coroutine.yield()
                        t = t - dt
                        object:set_color(Color(1, 1 - (0.5 * math.sin(t * 360) + 0.5), 1, 1 - (0.5 * math.sin(t * 360) + 0.5)))
                end
                object:set_color(Color(1, 1, 1, 1))
        end
 
        function HUDObjectives:_animate_update_objective(object)
                local TOTAL_T = 2
                local t = TOTAL_T
                object:set_y(0)
                while t > 0 do
                        local dt = coroutine.yield()
                        t = t - dt
                        object:set_y(math.round((1 + math.sin((TOTAL_T - t) * 450 * 2)) * (12 * (t / TOTAL_T))))
                end
                object:set_y(0)
        end
 
        function HUDObjectives:_get_text_width(obj)
                local _, _, w, _ = obj:text_rect()
                return w
        end    

        function HUDObjectives:reposition_objective()
        	self._panel:set_x(90)
        end

       
elseif RequiredScript == "lib/managers/hud/hudheisttimer" then
       
       
    function HUDHeistTimer:init(hud)
            self._hud_panel = hud.panel
            if self._hud_panel:child("heist_timer_panel") then
                    self._hud_panel:remove(self._hud_panel:child("heist_timer_panel"))
            end
           
            self._heist_timer_panel = self._hud_panel:panel({
                    visible = true,
                    name = "heist_timer_panel",
                    h = 40,
                    w = 50,
                    valign = "top",
                    layer = 0
            })
            self._timer_text = self._heist_timer_panel:text({
                    name = "timer_text",
                    text = "00:00:00",
                    font_size = 28,
                    font = tweak_data.hud.medium_font_noshadow,
                    color = Color.white,
                    align = "center",
                    vertical = "center",
                    layer = 1,
                    wrap = true,
                    word_wrap = true
            })
            self._last_time = 0
    end

local origi_tim = HUDHeistTimer.set_time
function HUDHeistTimer:set_time(time)
	if math.floor(time / 3600) > 0 and self._heist_timer_panel:w() == 50 then
		self._heist_timer_panel:set_w(80)
		self._timer_text:set_w(80)
		managers.hud:reposition_objective()
	end

	origi_tim(self, time)
end

	HUDChat.line_height = 16
	local HUDChat_receive_message_original = HUDChat.receive_message
	local HUDChat__create_input_panel_original = HUDChat._create_input_panel
	local init_original = HUDChat.init
	 
	function HUDChat:init(ws, hud)
	        self._ws = ws
	        self._hud_panel = hud.panel
	        self:set_channel_id(ChatManager.GAME)
	        self._output_width = 400
	        self._panel_width = 400
	        self._lines = {}
	        self._esc_callback = callback(self, self, "esc_key_callback")
	        self._enter_callback = callback(self, self, "enter_key_callback")
	        self._typing_callback = 0
	        self._skip_first = false
	        self._panel = self._hud_panel:panel({
	                name = "chat_panel",
	                x = 0,
	                h = 500,
	                w = self._panel_width,
	                halign = "left",
	                valign = "bottom"
	        })
	        --self._panel:set_bottom(self._panel:parent():h() - 112)
	        local output_panel = self._panel:panel({
	                name = "output_panel",
	                x = 0,
	                h = 10,
	                w = self._output_width,
	                layer = 1
	        })
	        output_panel:gradient({
	                name = "output_bg",
	                gradient_points = {
	                        0,
	                        Color.white:with_alpha(0),
	                        0.2,
	                        Color.white:with_alpha(0.25),
	                        1,
	                        Color.white:with_alpha(0)
	                },
	                layer = -1,
	                valign = "grow",
	                blend_mode = "sub"
	        })
	        self:_create_input_panel()
	        self:_layout_input_panel()
	        self:_layout_output_panel()
	        self._panel:set_bottom(self._panel:parent():h() - 120)
	        --self._panel:set_right(self._panel:parent():w()-50)
	        self._panel:set_left(0)
	    local output_panel = self._panel:child("output_panel")
	end

	function HUDChat:_layout_input_panel()
	        self._input_panel:set_w(400) 
	        local say = self._input_panel:child("say")
	        local input_text = self._input_panel:child("input_text")
	        input_text:set_left(say:right() + 4)
	        input_text:set_w(self._input_panel:w() - input_text:left())
	        local focus_indicator = self._input_panel:child("focus_indicator")
	        focus_indicator:set_shape(input_text:shape())
	        self._input_panel:set_y(self._input_panel:parent():h() - self._input_panel:h())
	end

	function HUDChat:_create_input_panel(...)
	        local tmp = tweak_data.menu.pd2_small_font_size
	        tweak_data.menu.pd2_small_font_size = HUDChat.line_height * 0.9
	        HUDChat__create_input_panel_original(self, ...)
	       -- self._input_panel:child("caret"):set_font_size(tweak_data.menu.pd2_small_font_size)
	        tweak_data.menu.pd2_small_font_size = tmp
	end

	function HUDChat:receive_message(name, message, color, icon)
	        local tmp = tweak_data.menu.pd2_small_font_size
	        tweak_data.menu.pd2_small_font_size = HUDChat.line_height * 0.9
	        HUDChat_receive_message_original(self, name, message, color, false)
	        tweak_data.menu.pd2_small_font_size = tmp
	end


elseif RequiredScript == "lib/managers/hud/hudsuspicion" then
	function HUDSuspicion:init(hud, sound_source)
		self._hud_panel = hud.panel
		self._sound_source = sound_source
		if self._hud_panel:child("suspicion_panel") then
			self._hud_panel:remove(self._hud_panel:child("suspicion_panel"))
		end
		self._suspicion_panel = self._hud_panel:panel({
			visible = false,
			name = "suspicion_panel",
			y = 0,
			valign = "center",
			layer = 1
		})
		self._misc_panel = self._suspicion_panel:panel({name = "misc_panel"})
		self._suspicion_panel:set_size(100, 100)
		self._suspicion_panel:set_center(self._suspicion_panel:parent():w() / 2, self._suspicion_panel:parent():h() / 2)
		local scale = 1.175
		local suspicion_left = self._suspicion_panel:bitmap({
			name = "suspicion_left",
			visible = true,
			texture = "guis/textures/pd2/hud_stealthmeter",
			color = Color(0, 1, 1),
			alpha = 1,
			valign = "center",
			w = 128 / 2,
			h = 128 / 2,
			blend_mode = "add",
			render_template = "VertexColorTexturedRadial",
			layer = 1
		})
		suspicion_left:set_size(suspicion_left:w() * scale, suspicion_left:h() * scale)
		suspicion_left:set_center_x(self._suspicion_panel:w() / 2)
		suspicion_left:set_center_y(self._suspicion_panel:h() / 2)
		local suspicion_right = self._suspicion_panel:bitmap({
			name = "suspicion_right",
			visible = true,
			texture = "guis/textures/pd2/hud_stealthmeter",
			color = Color(0, 1, 1),
			alpha = 1,
			valign = "center",
			w = 128 / 2,
			h = 128 / 2,
			blend_mode = "add",
			render_template = "VertexColorTexturedRadial",
			layer = 1
		})
		suspicion_right:set_size(suspicion_right:w() * scale, suspicion_right:h() * scale)
		suspicion_right:set_center(suspicion_left:center())
		suspicion_left:set_texture_rect(128, 0, -128, 128)
		local hud_stealthmeter_bg = self._misc_panel:bitmap({
			name = "hud_stealthmeter_bg",
			visible = true,
			texture = "guis/textures/pd2/hud_stealthmeter_bg",
			color = Color(0.2, 1, 1, 1),
			alpha = 0,
			valign = {0.5, 0},
			w = 128 / 2,
			h = 128 / 2,
			blend_mode = "normal"
		})
		hud_stealthmeter_bg:set_size(hud_stealthmeter_bg:w() * scale, hud_stealthmeter_bg:h() * scale)
		hud_stealthmeter_bg:set_center(suspicion_left:center())
		local suspicion_detected = self._suspicion_panel:text({
			name = "suspicion_detected",
			text = managers.localization:to_upper_text("hud_detected"),
			font_size = tweak_data.menu.pd2_medium_font_size,
			font = tweak_data.menu.pd2_medium_font,
			layer = 2,
			align = "center",
			vertical = "center",
			alpha = 0
		})
		suspicion_detected:set_text(utf8.to_upper(managers.localization:text("hud_suspicion_detected")))
		suspicion_detected:set_center(suspicion_left:center())
		local hud_stealth_eye = self._misc_panel:bitmap({
			name = "hud_stealth_eye",
			visible = true,
			texture = "guis/textures/pd2/hud_stealth_eye",
			alpha = 0,
			w = 32 / 2,
			h = 32 / 2,
			valign = "center",
			blend_mode = "add",
			layer = 1
		})
		hud_stealth_eye:set_center(suspicion_left:center_x(), suspicion_left:bottom() - 4)
		local hud_stealth_exclam = self._misc_panel:bitmap({
			name = "hud_stealth_exclam",
			visible = true,
			texture = "guis/textures/pd2/hud_stealth_exclam",
			alpha = 0,
			w = 32 / 2,
			h = 32 / 2,
			valign = "center",
			blend_mode = "add",
			layer = 1
		})
		hud_stealth_exclam:set_center(suspicion_left:center_x(), suspicion_left:top() - 4)
		self._eye_animation = nil
		self._suspicion_value = 0
	end
end
