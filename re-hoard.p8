pico-8 cartridge // http://www.pico-8.com
version 14
__lua__
--re-hoard
--copyright tinglar 2017-2018
--license gplv3 (gnu.org/licenses/gpl-3.0.en.html)
--revision 0

-- title music by 0xabad1dea
-- gameplay music based
-- on song by tanner helland



--
-- parameters
--
title_screen = true

--title screen: 64×16 starting from 0, 16

sprite_wall_constant = 64
sprite_floor_constant = 65
sprite_closed_door_constant = 68
sprite_open_door_constant = 69
sprite_closed_treasure_constant = 70
sprite_open_treasure_constant = 71

sprite_dragon_fly1_left_constant = 16
sprite_dragon_fly2_left_constant = 17
sprite_dragon_fly1_right_constant = 20
sprite_dragon_fly2_right_constant = 21
sprite_dragon_fly1_up_constant = 24
sprite_dragon_fly2_up_constant = 25
sprite_dragon_fly1_down_constant = 28
sprite_dragon_fly2_down_constant = 29
sprite_dragon_fire_left_constant = 18
sprite_dragon_fire_right_constant = 22
sprite_dragon_fire_up_constant = 26
sprite_dragon_fire_down_constant = 30
sprite_dragon_embarrass_left_constant = 19
sprite_dragon_embarrass_right_constant = 23
sprite_dragon_embarrass_up_constant = 27
sprite_dragon_embarrass_down_constant = 31
sprite_fireball_left_constant = 12
sprite_fireball_right_constant = 13
sprite_fireball_up_constant = 14
sprite_fireball_down_constant = 15
sprite_knight_walk1_constant = 74
sprite_knight_walk2_constant = 75
sprite_knight_hunt1_constant = 76
sprite_knight_hunt2_constant = 77
sprite_knight_fight_constant = 78
sprite_knight_got_hit_constant = 79
sprite_joy_walk1_constant = 80
sprite_joy_walk2_constant = 81
sprite_joy_hunt1_constant = 82
sprite_joy_hunt2_constant = 83
sprite_joy_fight_constant = 84
sprite_joy_got_hit_constant = 85
sprite_sadness_walk1_constant = 86
sprite_sadness_walk2_constant = 87
sprite_sadness_hunt1_constant = 88
sprite_sadness_hunt2_constant = 89
sprite_sadness_fight_constant = 90
sprite_sadness_got_hit_constant = 91
sprite_fear_walk1_constant = 96
sprite_fear_walk2_constant = 97
sprite_fear_hunt1_constant = 98
sprite_fear_hunt2_constant = 99
sprite_fear_fight_constant = 100
sprite_fear_got_hit_constant = 101
sprite_disgust_walk1_constant = 102
sprite_disgust_walk2_constant = 103
sprite_disgust_hunt1_constant = 104
sprite_disgust_hunt2_constant = 105
sprite_disgust_fight_horizontal_constant = 106
sprite_disgust_fight_vertical_constant = 124
sprite_disgust_got_hit_constant = 107
sprite_anger_walk1_constant = 112
sprite_anger_walk2_constant = 113
sprite_anger_hunt1_constant = 114
sprite_anger_hunt2_constant = 115
sprite_anger_fight_constant = 116
sprite_anger_got_hit_constant = 117
sprite_surprise_walk1_constant = 118
sprite_surprise_walk2_constant = 119
sprite_surprise_hunt1_constant = 120
sprite_surprise_hunt2_constant = 121
sprite_surprise_fight_constant = 122
sprite_surprise_got_hit_constant = 123
sprite_arrow_left_constant = 92
sprite_arrow_right_constant = 93 --could you not simply use flip_x?
sprite_arrow_up_constant = 94
sprite_arrow_down_constant = 95
sprite_lance_left_constant = 108
sprite_lance_right_constant = 109
sprite_lance_up_constant = 110
sprite_lance_down_constant = 111
sprite_explosive_off_constant = 126
sprite_explosive_on_constant = 127
sprite_warp1_constant = 72
sprite_warp2_constant = 73

music_title_constant = 1
music_gameplay_constant = 9
music_panic_constant = 22
music_failure_constant = 11
music_success_constant = 13
music_game_over_constant = 18

sound_effect_bump_constant = 63
sound_effect_fire_constant = 62
sound_effect_warp_constant = 61
sound_effect_blocked_fire_constant = 60
sound_effect_treasure_constant = 59
sound_effect_retreat_constant = 58

solidity_flag_constant = 0
hurts_dragon_flag_constant = 1
hurts_subordinate_flag_constant = 2

dungeon_initial_size_constant = 15

level = 0
dungeon = {}
total_floor_locations = {}
opponent_setup_floor_locations = {}
safe_floor_locations = {}



--
-- structures
--
--entity-component system code adapted from:
--selfsame at lexaloffle bbs
function _has(ecs_single_entity, ecs_component_value)
  for ecs_component_name in all(ecs_component_value) do
    if not ecs_single_entity[ecs_component_name] then
      return false
    end
  end
  return true
end

function ecs_system(ecs_component_value, ecs_entity_function)
  return function(ecs_every_entity)
    for ecs_single_entity in all(ecs_every_entity) do
      if _has(ecs_single_entity, ecs_component_value) then
        ecs_entity_function(ecs_single_entity)
      end
    end
  end
end


-- queue code adapted from:
-- deque implementation by pierre "catwell" chapuis
plain_queue_new = function()
  local queue_instance = {head = 0, tail = 0}
  return setmetatable(plain_queue_instance, {__index = methods})
end

plain_queue_length = function(self)
  return self.tail - self.head
end

plain_queue_push = function(self, item)
  assert(item ~= nil)
  self.tail = self.tail + 1
  self[self.tail] = item
end

plain_queue_pop = function(self)
  if self:queue_length() == 0 then
    return nil
  end
  local queue_instance = self[self.tail]
  self[self.tail] = nil
  self.tail = self.tail - 1
  return queue_instance
end


-- priority queue code adapted from:
-- rosetta code
priority_queue = {
    __index = {
        priority_queue_push = function(self, element_priority, element_value)
            local current_queue = self[element_priority]
            if not current_queue then
                current_queue = {first = 1, last = 0}
                self[element_priority] = current_queue
            end
            current_queue.last = current_queue.last + 1
            current_queue[current_queue.last] = element_value
        end,

        priority_queue_pop = function(self)
            for element_priority, current_queue in pairs(self) do
                if current_queue.first <= current_queue.last then
                    local element_value = current_queue[current_queue.first]
                    current_queue[current_queue.first] = nil
                    current_queue.first = current_queue.first + 1
                    return element_priority, element_value
                else
                    self[element_priority] = nil
                end
            end
        end, --please do not forget the commas!

        priority_queue_pour = function(self) --returns value without the priority
            for element_priority, current_queue in pairs(self) do
                if current_queue.first <= current_queue.last then
                    local element_value = current_queue[current_queue.first]
                    current_queue[current_queue.first] = nil
                    current_queue.first = current_queue.first + 1
                    return element_value
                else
                    self[element_priority] = nil
                end
            end
        end,

		priority_queue_length = function(self)
			return self.last - self.first + 1
		end

    },
    __call = function(cls)
        return setmetatable({}, cls)
    end
}

setmetatable(priority_queue, priority_queue)

-- usage:
-- declare = priority_queue()
-- declare:priority_queue_push(priority, value)
-- for priority, value in declare.pop, declare


--
-- algorithms
--
build_dungeon = function()
  local dungeon_size = dungeon_initial_size_constant + flr(level/3)

  local travelled_cells = plain_queue_new()
  local immediate_cells = plain_queue_new()
  local current_cell = nil

  local cell_content_above = dungeon[current_cell[1]][current_cell[2] - 1]
  local cell_content_below = dungeon[current_cell[1]][current_cell[2] + 1]
  local cell_content_back  = dungeon[current_cell[1] - 1][current_cell[2]]
  local cell_content_front = dungeon[current_cell[1] + 1][current_cell[2]]
  local cell_location_above = {current_cell[1], current_cell[2] - 1}
  local cell_location_below = {current_cell[1], current_cell[2] + 1}
  local cell_location_back  = {current_cell[1] - 1, current_cell[2]}
  local cell_location_front = {current_cell[1] + 1, current_cell[2]}


  for x = 1, dungeon_size do
    dungeon[x] = {}
    for y = 1, dungeon_size do
      if y == (1 or dungeon_size) then
        dungeon[x][y] = false
      end
    end
    if x == (1 or dungeon_size) then
      dungeon[x][y] = false
    end
  end

  -- this hard-coded section of the dungeon builder
  -- is an optimization of the cases of the cells
  -- that surround the north-west corner.
  dungeon[2][2] = true
  travelled_cells:plain_queue_push({2,2})

  if flr(rnd(1)) then
    dungeon[2][3] = true
    current_cell = {2,3}
    travelled_cells:plain_queue_push({2,3})
    dungeon[3][2] = false
  else
    dungeon[3][2] = true
    current_cell = {3,2}
    travelled_cells:plain_queue_push({3,2})
    dungeon[2][3] = false
  end

  repeat
    -- if current_cell holds {x,y}, then
    -- current_cell[1] holds x while current_cell[2] holds y.
    if cell_content_back ~= nil then
      immediate_cells:plain_queue_push(cell_location_back)
      -- immediate_cells is a queue that holds tables.
      -- after all, immediate_cells needs the locations, not their contents.
    end
    if cell_content_above ~= nil then
      immediate_cells:plain_queue_push(cell_location_above)
    end
    if cell_content_front ~= nil then
      immediate_cells:plain_queue_push(cell_location_front)
    end
    if cell_content_below ~= nil then
      immediate_cells:plain_queue_push(cell_location_below)
    end

    if immediate_cells:plain_queue_length() == 0 then
      current_cell = travelled_cells:plain_queue_pop()
    else
      local randomly = flr(rdm(immediate_cells:plain_queue_length())) + 1

      -- the program goes to the randomly-picked cell.
      current_cell = {immediate_cells.randomly}

      -- if the program travelled horizontally...
      if randomly % 2 == 1 then
        if cell_content_above == nil then
          cell_content_above = false
        end
        if cell_content_below == nil then
          cell_content_below = false
        end
      else
        if cell_content_back == nil then
          cell_content_back = false
        end
        if cell_content_front == nil then
          cell_content_front = false
        end
      end

      travelled_cells:plain_queue_push({current_cell[1], current_cell[2]})
      -- travelled_cells is a queue that holds tables.
      dungeon[current_cell] = true
    end
  until travelled_cells:plain_queue_length() == 0
end


collector_of_floor_cells = function()
  local collector_key = 1

  for x = 1, dungeon_size do
    for y = 1, dungeon_size do
      if dungeon[x][y] == true then
        total_floor_locations.collector_key = {x,y}
        collector_key = collector_key + 1
      end
    end
  end
end


collector_of_opponent_setup_cells = function()
  local collector_key = 1
  local bottom_half_of_dungeon = flr(dungeon_size/2)
  local current_location = nil

  for x = 1, dungeon_size do
    for y = 1, dungeon_size do
      current_location = total_floor_locations.collector_key
      if current_location.1 == bottom_half_of_dungeon or current_location.2 == bottom_half_of_dungeon then
        opponent_setup_floor_locations.collector_key = current_location
        collector_key = collector_key + 1
      end
    end
  end
end


collector_of_safe_cells = function()
  local collector_key = 1
  repeat
    safe_floor_locations.collector_key = total_floor_locations.collector_key
  until total_floor_locations.collector_key == nil
end


draw_dungeon = function()
  cls()
  for x in all(dungeon[1]) do
    for y in all(dungeon[1][2]) do
    -- lua can iterate over only one dimension at a time.
      if dungeon(x,y) == false then
        spr(wall_sprite_constant, x, y)
      else
        spr(floor_sprite_constant, x, y)
      end
    end
  end
  spr(door_sprite_constant, 2, 1)
  spr(closed_treasure_sprite_constant, dungeon_size - 1, dungeon_size - 1)
end


random_emotion = function()
  local seed = flr(rnd(5))
  if seed == 0 then
    return joy
  elseif seed = 1 then
    return sadness
  elseif seed == 2 then
    return fear
  elseif seed == 3 then
    return disgust
  elseif seed = 4 then
    return anger
  else
    return surprise
  end
end


place_knight = function()
  local knight_location = opponent_setup_floor_locations.#opponent_setup_floor_locations
  opponent_setup_floor_locations.#opponent_setup_floor_locations = nil

  return knight_location
end


place_subordinate = function()
  local random_location = flr(rdm(#opponent_setup_floor_locations))
  local subordinate_location = opponent_setup_floor_locations.random_location

  for sentinel = random_location, #opponent_setup_floor_locations - 1 do
    local next_location = sentinel + 1
    opponent_setup_floor_locations.sentinel = opponent_setup_floor_locations.next_location
  opponent_setup_floor_locations.#opponent_setup_floor_locations = nil

  return subordinate_location
end


--
--entity-component system
--

--systems:
---	- user control
--	- patrolling
--	- hunting
--	- pursuing
--	- self-destruction
--	- sprite

world = {}

populate = function()
  add(world, {
    emotion = knight,
    sprite = nil
    location = place_knight(),
    entity_x_position = location.1
    entity_y_position = location.2
    target = {},
    is_patrolling = false,
    is_hunting = false
    entity_x_movement = 0
    entity_y_movement = 0
  })

  local sentinel = 1
  while (sentinel <= (flr(dungeon_size / 3) + 1) do
    add(world, {
      emotion = random_emotion(),
      sprite = 0
      location = place_subordinate(),
      entity_x_position = location.1
      entity_y_position = location.2
      target = {},
      is_patrolling = false,
      is_hunting = false,
      is_hit = false
      entity_x_movement = 0
      entity_y_movement = 0
    })
  end

  add(world, {
    emotion = dragon,
    sprite = 0
    location = {2, 2},
    entity_x_position = location.1
    entity_y_position = location.2
    entity_x_movement = 0
    entity_y_movement = 0
  })
end


solid_collider_system = system({"emotion"},
  function(ecs_single_entity)
    return ecs_single_entity.location
  end)


solid_actor_system = system({"emotion"},
  function(ecs_single_entity)
    return ecs_single_entity.location
  end)


move_collider_system = system({"emotion"},
  function(ecs_single_entity)
    return ecs_single_entity.location
  end)


control_player_system = system({"emotion"},
  function(ecs_single_entity)
    return ecs_single_entity.location
  end)


draw_collider_system = system({"emotion"},
  function(ecs_single_entity)
    return ecs_single_entity.location
  end)

--adapted from scathe
collision_system = system({"entity_x_position", "entity_y_position"},
  function(ecs_single_entity)
    local tile_collision = false
    local x1 = ecs_single_entity.entity_x_position / 8
    local y1 = ecs_single_entity.entity_y_position / 8
    local x2 = (ecs_single_entity.entity_x_position + 7) / 8
    local y2 = (ecs_single_entity.entity_y_position + 7) / 8
    local northwest_touch = fget( mget(x1, y1), solidity_flag_constant)
    local southwest_touch = fget( mget(x1, y2), solidity_flag_constant)
    local northeast_touch = fget( mget(x2, y2), solidity_flag_constant)
    local southeast_touch = fget( mget(x2, y1), solidity_flag_constant)

    tile_collision = northwest_touch
                  or southwest_touch
                  or northeast_touch
                  or southeast_touch

    return tile_collision
  end)


function is_solid(x, y)
	value = mget(x, y)
	return fget(value, solidity_flag_constant)
end

function move_collider(actor)
	if not solid_actor(actor, actor.x_movement, 0) then
		actor.x_position += actor.x_movement
	end
	if not solid_actor(actor, 0, actor.y_movement) then
		actor.y_position += actor.y_movement
	end

	actor.current_frame += abs(actor.x_movement) * 4
	actor.current_frame += abs(actor.y_movement) * 4
	actor.current_frame %= actor.total_frames
	actor.time_advance += 1
end

function control_player(playable_actor)
	acceleration = 0.1
	--if (btn(0)) playable_actor.x_movement -= acceleration then
	--if (btn(1)) playable_actor.x_movement += acceleration then
	--if (btn(2)) playable_actor.y_movement -= acceleration then
	--if (btn(3)) playable_actor.y_movement += acceleration then
end

function draw_collider(actor)
	local sprite_x_position = (actor.x_position * 8) - 4
	local sprite_y_position = (actor.y_position * 8) - 4
	spr(actor.sprite + actor.current_frame, sprite_x_position, sprite_y_position)
end



locate_dragon_system = system({"emotion"},
  function(ecs_single_entity)
    if emotion == dragon then
      return ecs_single_entity.location
    end
  end)


return_to_your_places_system = system({"emotion", "location"},
  function(ecs_single_entity)
    if ecs_single_entity.emotion == knight then
      ecs_single_entity.location = place_knight()
    elseif ecs_single_entity.emotion == dragon then
      ecs_single_entity.location = {2, 2}
    else
      ecs_single_entity.location = place_subordinate()
    end
  end)


--patrol_system(world)


--a* code adapted from:
--richard "richy486" adem

--dungeon is a table of tables that have the x and y integers.
--keep this in mind when reviewing the a* code.
astar_heuristic = function(a, b)
	return abs(a[1] - b[1]) + abs(a[2]- b[2])
end

astar_get_special_tile = function(astar_tile_id)
	local astar_tile_x = nil
	local astar_tile_y = nil
	for astar_tile_x = 0, 15 do
		for astar_tile_y = 0, 15 do
			local astar_inspected_tile = mget(astar_tile_x, astar_tile_y) --contents
			if astar_inspected_tile == astar_tile_id then
				return {astar_tile_x, astar_tile_y} --location
			end
		end
	end
end

astar_map_to_index = function(astar_map_x, astar_map_y)
	return ( (astar_map_x + 1) * dungeon_initial_size_constant ) + astar_map_y
end

astar_index_to_map = function(astar_argued_index)
	local astar_map_x = (astar_argued_index - 1) / dungeon_initial_size_constant
	--the constant took the place of 16.
	local astar_map_y = astar_argued_index - (astar_map_x * dungeon_initial_size_constant)
	--the constant took the place of w.
	return {astar_map_x, astar_map_y}
end

astar_vector_to_index = function(astar_argued_vector)
	return astar_map_to_index(astar_argued_vector[1], astar_argued_vector[2])
end

astar_get_neighbor_locations = function(astar_your_location)
	local astar_all_neighbor_locations = {}
	local astar_your_x = astar_your_location[1]
	local astar_your_y = astar_your_location[2]

	local astar_neighbor_content_above = mget(astar_your_x, astar_your_y - 1)
	local astar_neighbor_content_below = mget(astar_your_x, astar_your_y + 1)
	local astar_neighbor_content_back = mget(astar_your_x - 1, astar_your_y)
	local astar_neighbor_content_front = mget(astar_your_x + 1, astar_your_y)
	local astar_neighbor_location_above = {astar_your_x, astar_your_y - 1}
	local astar_neighbor_location_below = {astar_your_x, astar_your_y + 1}
	local astar_neighbor_location_back = {astar_your_x - 1, astar_your_y}
	local astar_neighbor_location_front = {astar_your_x + 1, astar_your_y}

	if astar_your_x > 0 and (astar_neighbor_content_back ~= wall_sprite_constant) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_back})
	end
	if astar_your_y < 15 and (astar_neighbor_content_below ~= wall_sprite_constant) then
	--is the number 15 artificially restricting the capacity of the a*?
		add(astar_all_neighbor_locations, {astar_neighbor_location_below})
	end
	if astar_your_y > 0 and (astar_neighbor_content_above ~= wall_sprite_constant) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_above})
	end
	if astar_your_x < 15 and (astar_neighbor_content_front ~= wall_sprite_constant) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_front})
	end

	return astar_all_neighbor_locations
end

astar_search = function(my_location, my_target)
	local astar_start_location = my_location
	local astar_goal_location = my_target
	local astar_frontier = priority_queue_new()
	astar_frontier:priority_queue_push(0, astar_start_location)
	local astar_came_from = {}
	astar_came_from[astar_vector_to_index(astar_start_location)] = nil
	local astar_cost_so_far = {}
	astar_cost_so_far [astar_vector_to_index(astar_start_location)] = 0

	local astar_current_location = nil
	local astar_current_neighbors = nil
	local astar_next_index = nil
	local astar_new_cost = nil
	local astar_new_priority = nil

  local astar_final_path = plain_queue_new()
  local next_x = nil
  local next_y = nil

	while astar_frontier:priority_queue_length() > 0 do
		astar_current_location = astar_frontier:priority_queue_pop()
		if astar_vector_to_index(astar_current_location) == astar_vector_to_index(astar_goal_location) then
			break
		end
		astar_current_neighbors = astar_get_neighbor_locations(astar_current_location)
		for next_step in all(astar_current_neighbors) do
			astar_next_index = astar_vector_to_index(next)
			astar_new_cost = astar_cost_so_far[astar_vector_to_index(astar_current_location)]
			if (astar_cost_so_far[astar_next_index] == nil) or (astar_new_cost < astar_cost_so_far[astar_next_index]) then
				astar_cost_so_far[astar_next_index] = astar_new_cost
				astar_new_priority = astar_new_cost + astar_heuristic(astar_goal_location, next) --is the order reversed?
				astar_frontier:priority_queue_push(astar_new_priority, next)
				astar_came_from[astar_next_index] = astar_current_location

        if (astar_next_index ~= astar_vector_to_index(astar_start_location)) then
          next_x = next_step[1]
          next_y = next_step[2]
          astar_final_path:priority_queue_push = {next_x, next_y}
			end
		end
	end

  return astar_final_path
end


patrol_system = system({"emotion", "is_patrolling", "location", "target"},
  function(ecs_single_entity)
    local picked_target = {}
    local my_path = nil

    if ecs_single_entity.is_patrolling == true then
      --safe_floor_locations
      if ecs_single_entity.emotion == joy then
        if my_path:plain_queue_length{)} == 0 or my_path == nil then
          random_pick = flr(rnd(#safe_floor_locations))
          picked_target = safe_floor_locations.random_pick
          my_path = astar_search(ecs_single_entity.location, picked_target)
        else
          ecs_single_entity.location = my_path:plain_queue_pop()
        end
      -- sadness stays still when "patrolling".
      elseif ecs_single_entity.emotion == fear then
        --
      elseif ecs_single_entity.emotion == disgust then
        --
      elseif ecs_single_entity.emotion == anger then
        --
      elseif ecs_single_entity.emotion == surprise then
        --
      elseif ecs_single_entity.emotion == knight then
        ---
      end
    end
  end)


hunt_system = system({"emotion", "is_hunting", "location", "target"},
  function(ecs_single_entity)
    local picked_target = {}
    local my_path = {}

      if ecs_single_entity.is_hunting == true then
        ecs_single_entity.is_patrolling = false

        if ecs_single_entity.emotion == joy then
          astar_search(ecs_single_entity.location, locate_dragon)
          -- sadness stays still when "huntng".
        elseif ecs_single_entity.emotion == fear then
          --
        elseif ecs_single_entity.emotion == disgust then
          --
        elseif ecs_single_entity.emotion == anger then
          --
        elseif ecs_single_entity.emotion == surprise then
          --
        elseif ecs_single_entity.emotion == knight then
          ---
        end
      end
    end)


fight_system = system({"emotion", "is_hunting", "location", "target"},
  function(ecs_single_entity)

    if ecs_single_entity.is_hunting == true then
      ecs_single_entity.is_patrolling = false

      if ecs_single_entity.emotion == joy then
        astar_search(ecs_single_entity.location, locate_dragon)

      elseif ecs_single_entity.emotion == sadness then
        --
      elseif ecs_single_entity.emotion == fear then
        --
      elseif ecs_single_entity.emotion == disgust then
        --
      elseif ecs_single_entity.emotion == anger then
        --
      elseif ecs_single_entity.emotion == surprise then
        --
      elseif ecs_single_entity.emotion == knight then
        ---
      end
    end
  end)


selfdestruct_system = system({"is_hit", "location"},
  function(ecs_single_entity)
    del(world, {location == ecs_single_entity.location})
  end)



--
--basic pico-8 stuff
--
function _init()
--patrol_system(world)
end

function _draw()

end

function _update()

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000998000000899000009900000088000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000998000000899000008800000099000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222200000000000000000000000000002222220000000000000000000000002220022200000000000000000000000022200222000000000000000000000000
02222200000000ff000000000000000000222220ff0000000000000000000000002002000ffffff00f0220f000000000002002000ffffff00f0220f000000000
002222ff0000000f0000ff2200000000ff222200f000000022ff0000000000000ffffff00f0ff0f00ff22ff0000000000f2ff2f00f0220f00ffffff000000000
0022220f222222222222f22000000000f022220022222222022f2222000000000f0ff0f02222222222222222000000000f0220f0222222222222222200000000
22222222202222022022220000000000222222222022220200222202000000000002200020222202202222020f2222f000022000202222022022220202222220
20222202202222002022220000222ff02022220200222202002222020ff222000022220022022022220220222ffffff200222200220220222202202222222222
202002000222220002222200022222f00020020200222220002222200f2222200202202022000022220000222222222202022020220000222200002222222222
02202200222222002222220022222220002202200022222200222222022222220200002020000002200000022222222202000020200000022000000222222222
00000000000000000000000000000000000000000000000004440000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000044400000000004404440000000000000000000494000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000499940000000049404940000000000000000000049400000000000000000000000000000000000000000000000000000000000000000000000000
00000000004999940000000049404940000000000044404000004940000000000000000000000000000000000000000000000000000000000000000000000000
00000000004909400444000049404940004400000049404444049940000000000000000000000000000000000000000000000000000000000000000000000000
00000000049009404994000049404940049944004499404994049994000000000000000000000000000000000000000000000000000000000000000000000000
00000000499994044994000049444940049994004999404940049999400000000000000000000000000000000000000000000000000000000000000000000000
00000004999940449094000049999940049094004999940494049099940000000000000000000000000000000000000000000000000000000000000000000000
00000004999400499940044049999940499009404900940494004900940000000000000000000000000000000000000000000000000000000000000000000000
00000049494004994440494049449940499009404900940049404990094000000000000000000000000000000000000000000000000000000000000000000000
00000494494004940000440494004940499009404900994049400490099400000000000000000000000000000000000000000000000000000000000000000000
00004944994049940000000494004940449099404990994049400499099940000000000000000000000000000000000000000000000000000000000000000000
00049404994049944000000494004940049999404999994004900049999940000000000000000000000000000000000000000000000000000000000000000000
00494004940049994000000494004940049999400499999404940004999994000000000000000000000000000000000000000000000000000000000000000000
04944049940049994000000494004940044994000499949404994000499949400000000000000000000000000000000000000000000000000000000000000000
44440044440044440000000444004440004444000044404400444000044404440000000000000000000000000000000000000000000000000000000000000000
6660066655555555333b33bb5b5b55b5664444666633b36600000000554440000022220000022000066600000666000006660700066607000666000006660000
66600666555555553bb33b33555555556444444663333bb6000000000054440002000020000000000fff00000fff00000fff07000fff07000fff00000fff0000
0000000055555555b333b33bbb555555444444444333b3b40004400000054440002222000e0000e00fff07000fff07000fff07000fff07000fff00000fff0000
0066666655555555b33b333355555555444444444333333400444400000054400000000000eeee00006007000060070060606110606061106060100000600000
0066666655555555b33bbbb3555555554444444443b3333404444440000005400888888000000000066607000666070006660100066601000666677766666000
0066666655555555b33b333bb555555544444444433bb33405555550044444508000000880000008606061106060611000600000006000000060100000600000
0000000055555555b3bbbb3355555555444444444333bb3405444440044444408000000880000008060601000606010006060000060600000606000006060000
66600666555555553b3b33b355555555444444444333b33404444440044444400888888008888880600060000606000060006000060600006000600060006000
0aaa00000aaa00000aaaaaa00aaaaaa00aaa00000aaa00000ccc00000ccc00000ccc0c000ccc0c000ccc00000ccc000000000000000000000002000000002000
0aaa00000aaa00000aaaaaa00aaaaaa00aaa00000aaa00000ccc0c000ccc0c000ccc0cc00ccc0cc00ccc00000ccc000000000000000002000022200000002000
0aaaaaa00aaaaaa00aaa0a000aaa0a000aaa00000aaa00000ccc0cc00ccc0cc00ccc0c0c0ccc0c0c0ccc00000ccc000000200000000000200202020000002000
00a0aaa000a0aaa0a0a0aa00a0a0aa00a0a000aa00a0000000c00c0c00c00c0cc0c0cc00c0c0cc00c0c0000000c0000002000000222222220002000000002000
0aaa0a000aaa0a000aaa0a000aaa0a000aaaaaaaaaaaa0000ccc0c000ccc0c000ccc0c000ccc0c000cccccccccccc00022222222000000200002000000002000
a0a0aa00a0a0aa0000a0000000a0000000a000aa00a00000c0c0cc00c0c0cc0000c00c0000c00c0000c000c000c0000002000000000002000002000000202020
0a0a0a000a0a0a000a0a00000a0a00000a0a00000a0a00000c0c0c000c0c0c000c0c0c000c0c0c000c0c0c000c0c000000200000000000000002000000022200
a000a0000a0a0000a000a0000a0a0000a000a000a000a000c000cc000c0c0c00c000c0000c0c0000c000c000c000c00000000000000000000002000000002000
0222000002220000022200000222000002220000022200000bbb00000bbb00000bbb0b000bbb0b000bbb00000bbb00000000000000000000000b000000000000
0222000002220000022202000222020002220000022200000bbb00000bbb00000bbb0b000bbb0b000bbb00000bbb00000000000000000000000b000000000000
0222000002220000022202200222022002220200022200000bbb0b000bbb0b000bbb0b000bbb0b000bbb00000bbb000000000000000000000000000000000000
00200200002002002020220220202202202002200020000000b00b0000b00b00b0b0bb00b0b0bb00b0b0000000b0000000000000000000bb0000000000000000
0222022002220220022202200222022002222202222220000bbb0b000bbb0b000bbb0b000bbb0b000bbbbbbbbbbbb000bb000000000000000000000000000000
202022022020220200200200002002000020022000200000b0b0bb00b0b0bb0000b0000000b0000000b0000000b0000000000000000000000000000000000000
0202022002020220020200000202000002020200020200000b0b0b000b0b0b000b0b00000b0b00000b0b00000b0b00000000000000000000000000000000b000
200022000202020020002000020200002000200020002000b000b0000b0b0000b000b0000b0b0000b000b000b000b0000000000000000000000000000000b000
0888000008880000088808800888088008880000088800000999000009990000099900000999000009990000099900000bbb0000000000000000000000000000
0888000008880000088808880888088808880000088800000999000009990000099900000999000009990000099900000bbb0000000000000000000090909090
0888088008880880088808800888088008880000088800000999000009990000099900000999000009990000099900000bbb0000000000000009900009999900
00800888008008888080880080808800808000000080000000900000009000009090900090909000909000000090000000b00000000000000009900099999990
08880880088808800888080008880800088888888888800009990000099900000999000009990000099990009999900000b00000000000000009900009999900
80808800808088000080000000800000008008880080000090909000909090000090000000900000009000000090000000b00000000000000009900099999990
0808080008080800080800000808000008080080080800000909000009090000090900000909000009090000090900000bbb0000000000000000000009999900
8000800008080000800080000808000080008000800080009000900009090000900090000909000090009000900090000bbb0000000000000000000090909090
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000505050501010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000001000000010001010101030303030303030303030303030303030303070707070303030303030303030303030303030303030303030303030303030303000107
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011000001f3601f3501f3401f33022350223402233222342223502234021350213402235022342223522236024350243402433024340263600000026360000002636000000263600000026360263522635226340
011000002635026340263502634024350243422433224340243502436026350263402435024342243522433024360243502434024350223502234222332223402235022360243502434022350223422235222360
0110000026350263402635026340243502434224332243402435024360263502634024350243422435224330223502234022330223401f3601f3521f3421f3301f3401f3521f3421f3421f3421f3521f3421f340
011000001325013240132301324413200000001326513265132501324013230132441326000000132650000016250162401623016244000000000016265162651625016240162301624416260000001626500000
011000001825018240182301824413200000001826518265182501824018230182441826000000182650000016250162401623016244000000000016265162651525015240132301324413260000001326500000
011000001f7641f7501f7501f7401f7641f7501f7501f7401f7641f7501f7501f7401f7641f7501f7501f74022764227502275022740227502275021764217501f7641f7501f7501f7401f7501f7501f7401f750
011000002276422750227502274024764247502475024740247642475024750247402476424750247502474022764227502275022740227402275022764227501f7641f7501f7501f7401f7501f7501f7401f760
011000002b7622b7502b7402b750307623075030740307502e7622e7502e7402e7502d7622d7502d7402d7502b7622b7502b7402b7502d7622d7502d7402d750297622975029740297502b7622b7502b7402b750
011000002b7622b7502b7402b750307623075030740307502e7622e7502e7402e7502d7622d7502d7402d750297622975029740297502b7622b7502b7402b7502b7622b7502b7402b7502b7622b7502b7402b750
011000002b7622b7502b7402b750307623075030740307502e7622e7502e7402e7502d7622d7502d7402d750307623075030740307502b7622b7502b7402b7502b7622b7502b7402b7502b7422b7302b7202b710
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e0000183201632014320123200c3200c3200c3200c3200c3200c3200c3200c3200c32500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002332024320253202532524320253202632026325253202632027320273252632027320283202832529320293202932029320293202932029310293150030000100001000010000700000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00002232021320223202132022320213202232021320223202132022320213202232021320223202132022320213202232021320223202132022320213202232021320223202132022320213202232021320
010e00000a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a330093300a33009330
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011d00000c3200b3200c3200c32505320053200532005320053250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000232002320023200232008320083200232002320023200232002320023200832008320083250830002320023200232002320083200832002320023200232002320023200232008320083200832508300
010f00003061500000000000000000000000003061500000306150000000000000000000000000306150000030615000000000000000000000000030615000003061500000000000000030615000003061500000
010f00003061503330073300c3300c3350f3300f3350c3300a3300a3350e3300a33005330023300033000335003300033003330083300c3300e330083300833507330073350733008330073300b3300e33011330
010f00003061500000000000000018330183351833018335223302233022330223351633016335163301633520330203302033020335143301433514330143351f3301f335133301333513330133301333013335
010f0000133301333500000000001f3301f3352033020335163301633016330163351d3301d3351f3301f335143301433014330143351b3301b3351d3301d335133301333520330203351f3301f3301f3301f335
010f00001833018330183301833518330183351833018335223302233022330223351633016335163301633520330203302033020335143301433514330143351f3301f335133301333513330133302333023335
010f0000243302433024330243351f3301f3352033020335163301633016330163351d3301d3351f3301f335143301433014330143351b3301b3351d3301d335133301333520330203351f3301f3301f3301f335
010f00001833003330073300c3301f3300f330183300c33016330163300e3300a33005330023300033000335143300033003330083300c3300e330083300833513330133350733008330133300b3300e33011330
010f0000243302433024330243351f3301f3352033020335223302233022330223351d3301d3351f3301f335203302033020330203351b3301b3351d3301d3301f3301f33520330203351f3301f3352233022335
010f00003061503330073300c3300c3350f3300f3350c3300a3300a3350e3300a33005330023300033000335003300033003330083300c3300e330083300833507330073350733008330073300b3300e33011330
010f0000243402434024340243402434024340243402434024345243002430024300223002230022300223000f3300f3300f3300f3300f3300f3300f3350e3000e3300e3300e3300e33022340223402234022345
010f00002434024340243402434024340243402434024340243450e3000e3000000000000000000e3300e3350f3300f3300f3300f3300f3300f33010330103350e3300e3300e3300e3300e3300e3300e33522300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002873110731287001070028700107002870010700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400001c55029550295550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002435500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001073128731107312873110731287311073128731107310070000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000766006660056600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001014300400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00030544
00 01040644
00 00030544
00 02040644
00 00030744
00 01040844
00 00030744
02 02040944
00 41424344
00 14504344
00 14154344
00 14151644
00 14151644
01 14171844
00 14191a44
00 141b1c44
00 141b1c44
00 141b1c44
00 141b1c44
00 141d1e44
02 141d1f44
00 41424344
03 0f104344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
