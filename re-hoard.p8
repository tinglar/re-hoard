pico-8 cartridge // http://www.pico-8.com
version 14
__lua__
--re-hoard
--copyright tinglar 2017-2018
--license gplv3 (gnu.org/licenses/gpl-3.0.en.html)
--revision 0

--title music by 0xabad1dea
--gameplay music based
--on song by tanner helland



--
-- parameters
--

-- constants
-- title screen: 64 * 16 starting from 0, 16

sprite_wall = 64
sprite_floor = 65
sprite_closed_door = 68
sprite_open_door = 69
sprite_closed_treasure = 70
sprite_open_treasure = 71

sprite_dragon_fly1_left = 16
sprite_dragon_fly2_left = 17
sprite_dragon_fly1_right = 20
sprite_dragon_fly2_right = 21
sprite_dragon_fly1_up = 24
sprite_dragon_fly2_up = 25
sprite_dragon_fly1_down = 28
sprite_dragon_fly2_down = 29
sprite_dragon_fire_left = 18
sprite_dragon_fire_right = 22
sprite_dragon_fire_up = 26
sprite_dragon_fire_down = 30
sprite_dragon_embarrassed_left = 19
sprite_dragon_embarrassed_right = 23
sprite_dragon_embarrassed_up = 27
sprite_dragon_embarrassed_down = 31
sprite_fireball_left = 12
sprite_fireball_right = 13
sprite_fireball_up = 14
sprite_fireball_down = 15
sprite_knight_walk1 = 74
sprite_knight_walk2 = 75
sprite_knight_hunt1 = 76
sprite_knight_hunt2 = 77
sprite_knight_attack = 78
sprite_knight_got_hurt = 79
sprite_joy_walk1 = 80
sprite_joy_walk2 = 81
sprite_joy_hunt1 = 82
sprite_joy_hunt2 = 83
sprite_joy_attack = 84
sprite_joy_got_hurt = 85
sprite_sadness_walk1 = 86
sprite_sadness_walk2 = 87
sprite_sadness_hunt1 = 88
sprite_sadness_hunt2 = 89
sprite_sadness_attack = 90
sprite_sadness_got_hurt = 91
sprite_fear_walk1 = 96
sprite_fear_walk2 = 97
sprite_fear_hunt1 = 98
sprite_fear_hunt2 = 99
sprite_fear_attack = 100
sprite_fear_got_hurt = 101
sprite_disgust_walk1 = 102
sprite_disgust_walk2 = 103
sprite_disgust_hunt1 = 104
sprite_disgust_hunt2 = 105
sprite_disgust_attack_horizontal = 106
sprite_disgust_attack_vertical = 124
sprite_disgust_got_hurt = 107
sprite_anger_walk1 = 112
sprite_anger_walk2 = 113
sprite_anger_hunt1 = 114
sprite_anger_hunt2 = 115
sprite_anger_attack = 116
sprite_anger_got_hurt = 117
sprite_surprise_walk1 = 118
sprite_surprise_walk2 = 119
sprite_surprise_hunt1 = 120
sprite_surprise_hunt2 = 121
sprite_surprise_attack = 122
sprite_surprise_got_hurt = 123
sprite_arrow_left = 92
sprite_arrow_right = 93 --could you not simply use flip_x?
sprite_arrow_up = 94
sprite_arrow_down = 95
sprite_lance_left = 108
sprite_lance_right = 109
sprite_lance_up = 110
sprite_lance_down = 111
sprite_dynamite_off = 126
sprite_dynamite_on = 127
sprite_warp1 = 72
sprite_warp2 = 73

music_title = 1
music_gameplay = 9
music_panic = 22
music_failure = 11
music_success = 13
music_game_over = 18

sound_effect_bump = 63
sound_effect_fire = 62
sound_effect_warp = 61
sound_effect_blocked_fire = 60
sound_effect_treasure = 59
sound_effect_retreat = 58
sound_effect_fire_hit = 57
sound_effect_pierce = 56
sound_effect_explode = 55
sound_effect_slice = 54

flag_solidity = 0            -- adds 1
flag_hurts_dragon = 1        -- adds 2
flag_hurts_subordinate = 2   -- adds 4
flag_is_fireproof = 3        -- adds 8

initial_dungeon_size = 15



-- variables
title_phase = true
intermission_phase = false
setup_phase = false
normal_phase = false
panic_phase = false

current_level = 0
previous_level = nil
opportunities = 3
current_dungeon_size = initial_dungeon_size + flr(current_level / 3)
dungeon = {}
total_floor_locations = {}
opponent_setup_floor_locations = {}
safe_floor_locations = {}
dragon_location = nil
treasure_location = nil
got_treasure = false
is_fireball_there = false
fear_count = 0
arrow_count = 0
surprise_count = 0
dynamite_count = 0
highest_round = 0



--
-- structures
--

-- entity-component system code adapted from:
-- selfsame at lexaloffle bbs
_has = function(ecs_single_entity, ecs_component_value)
  for ecs_component_name in all(ecs_component_value) do
    if not ecs_single_entity[ecs_component_name] then
      return false
    end
  end

  return true
end

ecs_system = function(ecs_component_value, ecs_entity_function)
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
        end,

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



--
-- algorithms
--
title_screen = function()
  if title_phase == true then
    cls()
    sspr(0, 16, 64, 16, 32, 32)
    print("tinglar 2018", 40, 64)
    print("press Ž", 48, 84)
    print("highest round: "..(highest_round + 1), 0, 120)
    music(music_title)

    if btn(4) then
      cls()
      title_phase = false
      intermission_phase = true
      intermission_screen()
    end
  end
end


intermission_screen = function()
  if intermission_phase == true then
    music(-1)
    print("round "..(current_level + 1), 56, 56)
    print("opportunities: "..opportunities, 50, 70)

    if btn(4) then
      cls()
      intermission_phase = false
      setup_phase = true
      game_setup()
    end
  end
end


game_setup = function()
  if setup_phase == true then
    if current_level > previous_level or previous_level == nil then
      build_dungeon()
      collector_of_floor_cells()
      collector_of_opponent_setup_cells()
      collector_of_safe_cells()
      populate()
    else
      return_to_your_places_system(world)
    end

    draw_dungeon()
    subordinate_sprite_system(world)
    got_treasure = false

    setup_phase = false
    normal_phase = true
    start_patrolling_system(world)
    music(music_gameplay)
  end
end


build_dungeon = function()
  local travelled_cells = plain_queue_new()
  local immediate_cells = plain_queue_new()
  local current_cell = nil

  local cell_content_back  = dungeon[current_cell[1] - 1][current_cell[2]]
  local cell_content_front = dungeon[current_cell[1] + 1][current_cell[2]]
  local cell_content_above = dungeon[current_cell[1]][current_cell[2] - 1]
  local cell_content_below = dungeon[current_cell[1]][current_cell[2] + 1]
  local cell_location_back  = {current_cell[1] - 1, current_cell[2]}
  local cell_location_front = {current_cell[1] + 1, current_cell[2]}
  local cell_location_above = {current_cell[1], current_cell[2] - 1}
  local cell_location_below = {current_cell[1], current_cell[2] + 1}

  for x = 1, current_dungeon_size do
    dungeon[x] = {}
    for y = 1, current_dungeon_size do
      if y == (1 or current_dungeon_size) then
        dungeon[x][y] = false
      end
    end
    if x == (1 or current_dungeon_size) then
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
    if cell_content_front ~= nil then
      immediate_cells:plain_queue_push(cell_location_front)
    end
    if cell_content_above ~= nil then
      immediate_cells:plain_queue_push(cell_location_above)
    end
    if cell_content_below ~= nil then
      immediate_cells:plain_queue_push(cell_location_below)
    end

    if immediate_cells:plain_queue_length() == 0 then
      current_cell = travelled_cells:plain_queue_pop()
    else
      local randomly = flr (rdm (immediate_cells:plain_queue_length() ) ) + 1

      -- the program goes to the randomly-picked cell.
      current_cell = {immediate_cells["randomly"]}

      -- if the program travelled horizontally...
      if randomly < 3 then
        if cell_content_back == nil then
          cell_content_back = false
        end
        if cell_content_front == nil then
          cell_content_front = false
        end
      else
        if cell_content_above == nil then
          cell_content_above = false
        end
        if cell_content_below == nil then
          cell_content_below = false
        end
      end

      travelled_cells:plain_queue_push( {current_cell[1], current_cell[2]} )
      dungeon[current_cell] = true
    end
  until travelled_cells:plain_queue_length() == 0
end


collector_of_floor_cells = function()
  local collector_key = 1

  for x = 1, current_dungeon_size do
    for y = 1, current_dungeon_size do
      if dungeon[x][y] == true then
        total_floor_locations["collector_key"] = {x,y}
        collector_key = collector_key + 1
      end
    end
  end
end


collector_of_opponent_setup_cells = function()
  local collector_key = 1
  local top_half_of_dungeon = flr(current_dungeon_size / 2)
  local current_location = nil

  for x = 1, current_dungeon_size do
    for y = 1, current_dungeon_size do
      current_location = total_floor_locations["collector_key"]
      if current_location["1"] ~= top_half_of_dungeon or current_location["2"] ~= top_half_of_dungeon then
        opponent_setup_floor_locations["collector_key"] = current_location
        collector_key = collector_key + 1
      end
    end
  end
end


draw_dungeon = function()
  if title_phase and intermission_phase and setup_phase == false then
    for x in all(dungeon[1]) do
      for y in all(dungeon[1][2]) do
        if dungeon(x,y) == false then
          mset(sprite_wall, x, y)
        else
          mset(sprite_floor, x, y)
        end
      end
    end

    if got_treasure == true then
      mset(sprite_open_door, 2, 1)
      spr(sprite_open_treasure, treasure_location["1"], treasure_location["2"])
    else
      mset(sprite_closed_door, 2, 1)
      spr(sprite_closed_treasure, treasure_location["1"], treasure_location["2"])
    end
  end
end


--
--entity-component system
--
world = {}

populate = function()
  treasure_location = opponent_floor_locations["#opponent_floor_locations"]
  opponent_setup_floor_locations["#opponent_setup_floor_locations"] = nil

  add(world, {
    actor = knight,
    sprite = sprite_knight_walk1,
    location = place_knight(),
    x_position = location["1"],
    y_position = location["2"],
    orientation = north,
    cross_of_sight = {},
    target = {},
    x_goal = target["1"],
    y_goal = target["2"],
    is_patrolling = false,
    is_hunting = false,
    x_movement = 0,
    y_movement = 0,
    has_collided = false,
    touched_who = nil
  })

  while sentinel <= (flr (current_dungeon_size / 3) + 1) do
    add(world, {
      actor = generate_emotion(),
      sprite = sprite_knight_walk1,
      location = place_subordinate(),
      x_position = location["1"],
      y_position = location["2"],
      orientation = north,
      cross_of_sight = {},
      target = {},
      x_goal = target["1"],
      y_goal = target["2"],
      is_patrolling = false,
      is_hunting = false,
      is_hurt = false,
      x_movement = 0,
      y_movement = 0,
      has_collided = false,
      touched_who = nil
    })
  end

  add(world, {
    actor = dragon,
    sprite = sprite_dragon_fly1_down,
    location = {2, 2},
    x_position = location["1"],
    y_position = location["2"],
    is_hurt = false,
    x_movement = 0,
    y_movement = 0,
    has_collided = false,
    touched_who = nil
  })
end


place_knight = function()
  local knight_location = opponent_setup_floor_locations["#opponent_setup_floor_locations"]

  opponent_setup_floor_locations["#opponent_setup_floor_locations"] = nil

  return knight_location
end


place_subordinate = function()
  repeat
    local random_location = flr(rdm(#opponent_setup_floor_locations))
  until opponent_setup_floor_locations["random_location"] ~= nil

  local subordinate_location = opponent_setup_floor_locations["random_location"]
  opponent_setup_floor_locations["random_location"] = nil

  return subordinate_location
end


generate_emotion = function()
  local seed = flr(rnd(5))

  if seed == 0 then
    return joy
  elseif seed == 1 then
    return sadness
  elseif seed == 2 then
    fear_count = fear_count + 1
    return fear
  elseif seed == 3 then
    return disgust
  elseif seed == 4 then
    return anger
  else
    surprise_count = surprise_count + 1
    return surprise
  end
end


subordinate_sprite_system = ecs_system({"actor", "sprite"},
  function(ecs_single_entity)
    if setup_phase == true then
      if ecs_single_entity.actor == joy then
        ecs_single_entity.sprite = sprite_joy_walk1
      elseif ecs_single_entity.actor == sadness then
        ecs_single_entity.sprite = sprite_sadness_walk1
      elseif ecs_single_entity.actor == fear then
        ecs_single_entity.sprite = sprite_fear_walk1
      elseif ecs_single_entity.actor == disgust then
        ecs_single_entity.sprite = sprite_disgust_walk1
      elseif ecs_single_entity.actor == anger then
        ecs_single_entity.sprite = sprite_anger_walk1
      elseif ecs_single_entity.actor == surprise then
        ecs_single_entity.sprite = sprite_surprise_walk1
      end
    end
  end)


start_patrolling_system = ecs_system({"is_patrolling"},
  function(ecs_single_entity)
    if normal_phase ==  true then
      if ecs_single_entity.is_patrolling == false then
        ecs_single_entity.is_patrolling = true
      end
    end
  end)


run_gameplay = function()
  if normal_phase or panic_phase == true then
    orientation_system(world)
    set_cross_of_sight_system(world)
    collision_system(world)
    move_collider_system(world)
    collector_of_safe_cells(world)
    control_dragon_system(world)
    fireball_system(world)
    locate_dragon_system(world)
    patrol_system(world)
    patrol_to_hunt_system(world)
    hunt_system(world)
    back_to_normal()
    fight_system(world)
    arrow_system(world)
    dynamite_system(world)
    remove_hazards_from_safe_locations_system(world)
    did_that_hurt_system(world)
    attack_dragon_system(world)
    lance_system(world)
    embarrass_dragon_system(world)
    hurt_subordinate_system(world)
    treasure_system(world)
    won_stage()
  end
end


orientation_system = ecs_system({"orientation", "x_movement", "y_movement"},
  function(ecs_single_entity)
      if ecs_single_entity.x_movement < 0 then
        ecs_single_entity.orientation = west
      elseif ecs_single_entity.x_movement > 0 then
        ecs_single_entity.orientation = east
      end

      if ecs_single_entity.y_movement < 0 then
        ecs_single_entity.orientation = north
      elseif ecs_single_entity.y_movement > 0 then
        ecs_single_entity.orientation = south
      end
  end)


set_cross_of_sight_system = ecs_system({"orientation", "cross_of_sight",
                                  "x_location", "y_location"},
  function(ecs_single_entity)
    ecs_single_entity.cross_of_sight = {}
    local look = 1

    if ecs_single_entity.orientation == west then
      while mget(ecs_single_entity.x_location - look, ecs_single_entity.y_location) == sprite_floor do
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location - look, ecs_single_entity.y_location} )
        look = look + 1
      end
      if mget(ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1} )
      end
      if mget(ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1} )
      end

    elseif ecs_single_entity.orientation == east then
      while mget(ecs_single_entity.x_location + look, ecs_single_entity.y_location) == sprite_floor do
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location + look, ecs_single_entity.y_location} )
        look = look + 1
      end
      if mget(ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1} )
      end
      if mget(ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1} )
      end

    elseif ecs_single_entity.orientation == north then
      while mget(ecs_single_entity.x_location, ecs_single_entity.y_location - look) == sprite_floor do
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location, ecs_single_entity.y_location - look} )
        look = look + 1
      end
      if mget(ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1} )
      end
      if mget(ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1} )
      end

    elseif ecs_single_entity.orientation == south then
      while mget(ecs_single_entity.x_location, ecs_single_entity.y_location + look) == sprite_floor do
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location, ecs_single_entity.y_location + look} )
        look = look + 1
      end
      if mget(ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1} )
      end
      if mget(ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1) == sprite_floor then
        add (ecs_single_entity.cross_of_sight,
              {ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1} )
      end

    end
  end)


-- collision code adapted from:
-- scathe
collision_system = ecs_system({"x_position", "y_position",
                          "has_collided", "touched_who"},
  function(ecs_single_entity)
    local sprite_size = 8
    local x1 = ecs_single_entity.x_position
    local y1 = ecs_single_entity.y_position
    local x2 = ecs_single_entity.x_position + 1
    local y2 = ecs_single_entity.y_position + 1
    local northwest_touch = fget (mget (x1, y1), flag_solidity)
    local southwest_touch = fget (mget (x1, y2), flag_solidity)
    local northeast_touch = fget (mget (x2, y2), flag_solidity)
    local southeast_touch = fget (mget (x2, y1), flag_solidity)

    ecs_single_entity.has_collided = northwest_touch
                  or southwest_touch
                  or northeast_touch
                  or southeast_touch
    if northwest_touch == true then
      ecs_single_entity.touched_who = fget (mget (x1, y1) )
    elseif southwest_touch == true then
      ecs_single_entity.touched_who = fget (mget (x1, y2) )
    elseif northeast_touch == true then
      ecs_single_entity.touched_who = fget (mget (x2, y2) )
    elseif southeast_touch == true then
      ecs_single_entity.touched_who = fget (mget (x2, y1) )
    end


    local my_x = ecs_single_entity.x_position
    local my_y = ecs_single_entity.y_position
    local your_x = other.position.x
    local your_y = other.position.y

    if your_x + sprite_size > my_x
    and your_y + sprite_size > my_y
    and your_x < my_x + sprite_size
    and your_y < my_y + sprite_size then
      ecs_single_entity.has_collided = true
      ecs_single_entity.touched_who = other
    end
  end)


move_collider_system = ecs_system({"has_collided",
                              "x_position", "y_position",
                              "x_movement", "y_movement"},
  function(ecs_single_entity)
    if normal_phase or panic_phase == true then
      if ecs_single_entity.has_collided == false then
        ecs_single_entity.x_position = ecs_single_entity.x_position + ecs_single_entity.x_movement
        ecs_single_entity.y_position = ecs_single_entity.y_position + ecs_single_entity.y_movement
      end
    end
  end)


collector_of_safe_cells = function()
  local collector_key = 1

  repeat
    safe_floor_locations["collector_key"] = total_floor_locations["collector_key"]
  until total_floor_locations["collector_key"] == nil
end


control_dragon_system = ecs_system({"actor", "is_hurt", "sprite", "x_movement", "y_movement"},
  function(ecs_single_entity)
    if normal_phase or panic_phase == true then
      if ecs_single_entity.actor == dragon and ecs_single_entity.is_hurt == false then
        if btn(0) then
          ecs_single_entity.x_movement = -0.2
        end
        if btn(1) then
          ecs_single_entity.x_movement = 0.2
        end
        if not btn(0) and not btn(1) then
          ecs_single_entity.x_movement = 0
        end
        if btn(2) then
          ecs_single_entity.y_movement = -0.2
        end
        if btn(3) then
          ecs_single_entity.y_movement = 0.2
        end
        if not btn(2) and not btn(3) then
          ecs_single_entity.y_movement = 0
        end
        if btnp(4) then
          if is_fireball_there == false then
            is_fireball_there = true
            if ecs_single_entity.sprite == sprite_dragon_fly1_left or sprite_dragon_fly2_left then
              add(world, {
                actor = fireball,
                sprite = sprite_fireball_left,
                location = {ecs_single_entity.x_position - 1, ecs_single_entity.y_position},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = -0.4,
                y_movement = 0,
                has_collided = false,
                touched_who = nil
              })
            elseif ecs_single_entity.sprite == sprite_dragon_fly1_right or sprite_dragon_fly2_right then
              add(world, {
                actor = fireball,
                sprite = sprite_fireball_right,
                location = {ecs_single_entity.x_position + 1, ecs_single_entity.y_position},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0.4,
                y_movement = 0,
                has_collided = false,
                touched_who = nil
              })
            elseif ecs_single_entity.sprite == sprite_dragon_fly1_up or sprite_dragon_fly2_up then
              add(world, {
                actor = fireball,
                sprite = sprite_fireball_up,
                location = {ecs_single_entity.x_position, ecs_single_entity.y_position - 1},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0,
                y_movement = -0.4,
                has_collided = false,
                touched_who = nil
              })
            elseif ecs_single_entity.sprite == sprite_dragon_fly1_down or sprite_dragon_fly2_down then
              add(world, {
                actor = fireball,
                sprite = sprite_fireball_down,
                location = {ecs_single_entity.x_position, ecs_single_entity.y_position + 1},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0,
                y_movement = 0.4,
                has_collided = false,
                touched_who = nil
              })
            end
          end
        end
      end
    end
  end)


draw_normal_dragon_system = ecs_system({"actor", "x_movement", "y_movement", "sprite"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == dragon then
      if ecs_single_entity.x_movement < 0 then
        if ecs_single_entity.sprite == sprite_dragon_fly2_left then
          ecs_single_entity.sprite = sprite_dragon_fly1_left
        else
          ecs_single_entity.sprite = sprite_dragon_fly2_left
        end
      end
      if ecs_single_entity.x_movement > 0 then
        if ecs_single_entity.sprite == sprite_dragon_fly2_right then
          ecs_single_entity.sprite = sprite_dragon_fly1_right
        else
          ecs_single_entity.sprite = sprite_dragon_fly2_right
        end
      end
      if ecs_single_entity.y_movement < 0 then
        if ecs_single_entity.sprite == sprite_dragon_fly2_up then
          ecs_single_entity.sprite = sprite_dragon_fly1_up
        else
          ecs_single_entity.sprite = sprite_dragon_fly2_up
        end
      end
      if ecs_single_entity.y_movement > 0 then
        if ecs_single_entity.sprite == sprite_dragon_fly2_down then
          ecs_single_entity.sprite = sprite_dragon_fly1_down
        else
          ecs_single_entity.sprite = sprite_dragon_fly2_down
        end
      end

      if btnp(4) then
        if normal_phase or panic_phase == true then
          if ecs_single_entity.sprite == sprite_dragon_fly1_left or sprite_dragon_fly2_left then
            ecs_single_entity.sprite = sprite_dragon_fire_left
          elseif ecs_single_entity.sprite == sprite_dragon_fly1_right or sprite_dragon_fly2_right then
            ecs_single_entity.sprite = sprite_dragon_fire_right
          elseif ecs_single_entity.sprite == sprite_dragon_fly1_up or sprite_dragon_fly2_up then
            ecs_single_entity.sprite = sprite_dragon_fire_up
          elseif ecs_single_entity.sprite == sprite_dragon_fly1_down or sprite_dragon_fly2_down then
            ecs_single_entity.sprite = sprite_dragon_fire_down
          end
        end
      end
    end
  end)


fireball_system = ecs_system({"actor", "touched_who", "has_collided"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == fireball
    and ecs_single_entity.has_collided == true then
      if ecs_single_entity.touched_who == flag_solidity then
        sfx(sound_effect_bump, 3)
      elseif ecs_single_entity.touched_who == flag_solidity + flag_hurts_dragon then
        sfx(sound_effect_fire_hit, 3)
      elseif ecs_single_entity.touched_who == flag_solidity + flag_hurts_dragon + flag_is_fireproof then
        sfx(sound_effect_blocked_fire, 3)
      end

      del(world, {actor == fireball})
      is_fireball_there = false
    end
  end)


locate_dragon_system = ecs_system({"actor"},
  function(ecs_single_entity)
    if actor == dragon then
      dragon_location = ecs_single_entity.location
    end
  end)


return_to_your_places_system = ecs_system({"actor", "location"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == knight then
      ecs_single_entity.location = place_knight()
    elseif ecs_single_entity.actor == dragon then
      ecs_single_entity.location = {2, 2}
    else
      ecs_single_entity.location = place_subordinate()
    end
  end)


-- a* code adapted from:
-- richard "richy486" adem

-- dungeon is a table of tables that have the x and y integers.
-- keep this in mind when reviewing the a* code.
astar_heuristic = function(a, b)
	return abs(a[1] - b[1]) + abs(a[2] - b[2])
end


astar_get_special_tile = function(astar_tile_id)
	local astar_tile_x = nil
	local astar_tile_y = nil
	for astar_tile_x = 0, current_dungeon_size do
		for astar_tile_y = 0, current_dungeon_size do
			local astar_inspected_tile = mget(astar_tile_x, astar_tile_y)
			if astar_inspected_tile == astar_tile_id then
				return {astar_tile_x, astar_tile_y}
			end
		end
	end
end


astar_map_to_index = function(astar_map_x, astar_map_y)
	return ( (astar_map_x + 1) * current_dungeon_size ) + astar_map_y
end


astar_index_to_map = function(astar_index)
	local astar_map_x = (astar_index - 1) / (current_dungeon_size + 1)
	-- the constant took the place of 16.
	local astar_map_y = astar_index - (astar_map_x * current_dungeon_size)
	-- the constant took the place of w.
	return {astar_map_x, astar_map_y}
end

astar_vector_to_index = function(astar_vector)
	return astar_map_to_index(astar_vector[1], astar_vector[2])
end


astar_get_neighbor_locations = function(astar_your_location)
	local astar_all_neighbor_locations = {}
	local astar_your_x = astar_your_location[1]
	local astar_your_y = astar_your_location[2]

	local astar_neighbor_tile_back = mget(astar_your_x - 1, astar_your_y)
	local astar_neighbor_tile_front = mget(astar_your_x + 1, astar_your_y)
  local astar_neighbor_tile_above = mget(astar_your_x, astar_your_y - 1)
	local astar_neighbor_tile_below = mget(astar_your_x, astar_your_y + 1)
	local astar_neighbor_location_back = {astar_your_x - 1, astar_your_y}
	local astar_neighbor_location_front = {astar_your_x + 1, astar_your_y}
  local astar_neighbor_location_above = {astar_your_x, astar_your_y - 1}
  local astar_neighbor_location_below = {astar_your_x, astar_your_y + 1}

	if astar_your_x > 0 and (astar_neighbor_tile_back == sprite_floor) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_back})
	end
	if astar_your_x < current_dungeon_size and (astar_neighbor_tile_front == sprite_floor) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_front})
	end
  if astar_your_y > 0 and (astar_neighbor_tile_above == sprite_floor) then
		add(astar_all_neighbor_locations, {astar_neighbor_location_above})
	end
  if astar_your_y < current_dungeon_size and (astar_neighbor_tile_below == sprite_floor
  ) then
    add(astar_all_neighbor_locations, {astar_neighbor_location_below})
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

  -- if the target is out of bounds,
  -- then the following conditionals readjust the target
  -- to within the bounds
  if astar_goal_location["1"] < 2 then
    astar_goal_location["1"] = 2
  elseif astar_goal_location["1"] > current_dungeon_size - 1 then
    astar_goal_location["1"] = current_dungeon_size - 1
  end
  if astar_goal_location["2"] < 2 then
    astar_goal_location["2"] = 2
  elseif astar_goal_location["2"] > current_dungeon_size - 1 then
    astar_goal_location["2"] = current_dungeon_size - 1
  end

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
				astar_new_priority = astar_new_cost + astar_heuristic(astar_goal_location, next_step)
				astar_frontier:priority_queue_push(astar_new_priority, next_step) -- is the order reversed?
				astar_came_from[astar_next_index] = astar_current_location

        if (astar_next_index ~= astar_vector_to_index(astar_start_location) ) then
          next_x = next_step[1]
          next_y = next_step[2]
          astar_final_path:plain_queue_push({next_x, next_y}) -- is the order reversed, too?
        end
			end
		end
	end

  return astar_final_path
end


remove_hazards_from_safe_locations_system = ecs_system({"actor", "location", "sprite"},
  function(ecs_single_entity)
    for key, value in pairs(safe_floor_locations) do

      if ecs_single_entity.actor == fireball or arrow or dynamite then
        if ecs_single_entity.location == value then
          del(key, value)
        end
      end

      if ecs_single_entity.actor == fireball or arrow then
        if ecs_single_entity.sprite == sprite_fireball_up or sprite_arrow_up then
          if {ecs_single_entity.x_position, ecs_single_entity.y_position - 1} == value then
            del(key, value)
          end
        elseif ecs_single_entity.sprite == sprite_fireball_down or sprite_arrow_down then
          if {ecs_single_entity.x_position, ecs_single_entity.y_position + 1} == value then
            del(key, value)
          end
        elseif ecs_single_entity.sprite == sprite_fireball_left or sprite_arrow_left then
          if {ecs_single_entity.x_position - 1, ecs_single_entity.y_position} == value then
            del(key, value)
          end
        elseif ecs_single_entity.sprite == sprite_fireball_right or sprite_arrow_right then
          if {ecs_single_entity.x_position + 1, ecs_single_entity.y_position} == value then
            del(key, value)
          end
        end
      end

      if ecs_single_entity.actor == dynamite then
        if value == {ecs_single_entity.x_position - 1, ecs_single_entity.y_position}
        or {ecs_single_entity.x_position + 1, ecs_single_entity.y_position}
        or {ecs_single_entity.x_position, ecs_single_entity.y_position - 1}
        or {ecs_single_entity.x_position, ecs_single_entity.y_position + 1}
        or {ecs_single_entity.x_position - 1, ecs_single_entity.y_position - 1}
        or {ecs_single_entity.x_position - 1, ecs_single_entity.y_position + 1}
        or {ecs_single_entity.x_position + 1, ecs_single_entity.y_position - 1}
        or {ecs_single_entity.x_position + 1, ecs_single_entity.y_position + 1} then
          del(key, value)
        end
      end

    end
  end)


patrol_system = ecs_system({"actor",
                        "is_patrolling", "x_movement", "y_movement",
                        "location", "x_position", "y_position",
                        "target", "x_goal", "y_goal"},
  function(ecs_single_entity)
    local picked_target = {}
    if ecs_single_entity.actor == knight then
      local knight_path = {}
      local knight_step = 1
    else
      local my_path = plain_queue_new()
    end

    if ecs_single_entity.is_patrolling == true then
      if ecs_single_entity.actor == joy then
        if my_path:plain_queue_length() == 0 then
          random_pick = flr (rnd (#safe_floor_locations) )
          picked_target = safe_floor_locations["random_pick"]
          my_path = astar_search(ecs_single_entity.location, picked_target)
        else
          ecs_single_entity.target = my_path:plain_queue_pop()
          move_opponent()
        end

      -- sadness stays still when "patrolling".

      elseif ecs_single_entity.actor == fear then
        if my_path:plain_queue_length() == 0 then
          my_path:plain_queue_push(ecs_single_entity.location)
          for key, value in pairs(safe_floor_locations) do
            if {ecs_single_entity.x_location, ecs_single_entity.y_location - 1} == value then
              my_path:plain_queue_push(value)
              break
            elseif {ecs_single_entity.x_location, ecs_single_entity.y_location + 1} == value then
              my_path:plain_queue_push(value)
              break
            elseif {ecs_single_entity.x_location - 1, ecs_single_entity.y_location} == value then
              my_path:plain_queue_push(value)
              break
            elseif {ecs_single_entity.x_location + 1, ecs_single_entity.y_location} == value then
              my_path:plain_queue_push(value)
              break
            end
          end
        else
          ecs_single_entity.target = my_path:plain_queue_pop()
          my_path:plain_queue_push(ecs_single_entity.target)
          move_opponent()
        end

      elseif ecs_single_entity.actor == disgust then
        if my_path:plain_queue_length() == 0 then
          for key, value in pairs(safe_floor_locations) do
            if ecs_single_entity.location ~= value then
              local check_x_location = value["1"]
              local check_y_location = value["2"]

              if mget(check_x_location - 1, check_y_location) == sprite_floor
              and mget(check_x_location + 1, check_y_location) == sprite_floor
              and mget(check_x_location, check_y_location - 1) == sprite_floor
              and mget(check_x_location, check_y_location + 1) == sprite_floor
              and mget(check_x_location - 1, check_y_location - 1) == sprite_floor
              and mget(check_x_location - 1, check_y_location + 1) == sprite_floor
              and mget(check_x_location + 1, check_y_location - 1) == sprite_floor
              and mget(check_x_location + 1, check_y_location + 1) == sprite_floor then
                picked_target = value
                break
              end
            end
          end
          my_path = astar_search(ecs_single_entity.location, picked_target)

        else
          ecs_single_entity.target = my_path:plain_queue_pop()
          move_opponent()
        end

      elseif ecs_single_entity.actor == anger then
        if my_path:plain_queue_length() == 0 then
          local top_right_corner = flr(#safe_floor_locations / 2) - 1
          local bottom_left_corner = flr(#safe_floor_locations / 2) + 1
          my_path:plain_queue_push(safe_floor_locations["1"])
          my_path:plain_queue_push(safe_floor_locations["top_right_corner"])
          my_path:plain_queue_push(safe_floor_locations["#safe_floor_locations"])
          my_path:plain_queue_push(safe_floor_locations["bottom_left_corner"])
        else
          ecs_single_entity.target = my_path:plain_queue_pop()
          my_path:plain_queue_push(ecs_single_entity.target)
          move_opponent()
        end

      elseif ecs_single_entity.actor == surprise then
        if my_path:plain_queue_length() == 0 then
          random_pick = flr (rnd (#safe_floor_locations) )
          picked_target = safe_floor_locations["random_pick"]
          my_path = astar_search(ecs_single_entity.location, picked_target)
          if dynamite_count < surprise_count then
            add(world, {
              actor = dynamite,
              sprite = sprite_dynamite_off,
              location = {ecs_single_entity.x_position, ecs_single_entity.y_position},
              x_position = location["1"],
              y_position = location["2"],
              has_collided = false,
              touched_who = nil,
              fuse_count = flr (rnd (9) )
            })
            dynamite_count = dynamite_count + 1
          end
        else
          ecs_single_entity.target = my_path:plain_queue_pop()
          move_opponent()
        end

      elseif ecs_single_entity.actor == knight then
        if #knight_path == 0 then
          if mget(last_location["1"] - 1, last_location["2"]) == sprite_floor then
            add (knight_path, {last_location["1"] - 1, last_location["2"]} )
          end
          if mget(last_location["1"] - 1, last_location["2"] - 1) == sprite_floor then
            add (knight_path, {last_location["1"] - 1, last_location["2"] - 1} )
          end
          if mget(last_location["1"], last_location["2"] - 1) == sprite_floor then
            add (knight_path, {last_location["1"], last_location["2"] - 1} )
          end
        else
          if knight_step <= #knight_path then
            ecs_single_entity.target = knight_path["knight_step"]
            move_opponent()
            knight_step = knight_step + 1
          else
            local hold = knight_path["knight_path"]
            knight_path["knight_path"] = knight_path["1"]
            knight_path["1"] = hold
            knight_step = 1
          end
        end

      end
    end
  end)


move_opponent = function()
  while ecs_single_entity.x_position ~= ecs_single_entity.x_goal
    and ecs_single_entity.y_position ~= ecs_single_entity.y_goal do

      if ecs_single_entity.touched_who < 1 then
        if ecs_single_entity.x_position < ecs_single_entity.x_goal then
          ecs_single_entity.x_movement = 0.1
        elseif ecs_single_entity.x_position > ecs_single_entity.x_goal then
          ecs_single_entity.x_movement = -0.1
        end
        if ecs_single_entity.y_position < ecs_single_entity.y_goal then
          ecs_single_entity.y_movement = 0.1
        elseif ecs_single_entity.y_position > ecs_single_entity.y_goal then
          ecs_single_entity.y_movement = -0.1
        end
      end

  end
end


patrol_to_hunt_system = ecs_system({"actor", "is_patrolling", "is_hunting"},
  function(ecs_single_entity)
    if ecs_single_entity.is_hunting == false then
      if ecs_single_entity.actor == knight and got_treasure == true then
        ecs_single_entity.is_patrolling = false
        ecs_single_entity.is_hunting = true
      end

      local look_around = ecs_single_entity.cross_of_sight
      for check in all(look_around) do
        if dragon_location == look_around["check"] then
          ecs_single_entity.is_patrolling = false
          ecs_single_entity.is_hunting = true
        end
      end
    end
  end)


hunt_system = ecs_system({"actor", "is_hunting", "location", "target",
                      "x_position", "y_position", "x_goal", "y_goal",
                      "x_movement", "y_movement", "orientation"},
  function(ecs_single_entity)
    local picked_target = {}
    local my_path = nil
    local pause_counter = 3

      if ecs_single_entity.is_hunting == true then
        if panic_phase == false then
          panic_phase = true
          music(music_panic)
        end

        if ecs_single_entity.actor == joy or surprise then
          if ecs_single_entity.actor == surprise then
            while pause_counter > 0 do
              pause_counter = pause_counter - 1
            end
          end

          if my_path:plain_queue_length() == 0 then
            my_path = astar_search(ecs_single_entity.location, dragon_location)
          else
            ecs_single_entity.target = my_path:plain_queue_pop()
            move_opponent()
          end

        -- sadness stays still when "hunting".

        elseif ecs_single_entity.actor == fear then
          while pause_counter > 0 do
            pause_counter = pause_counter - 1
          end
          if arrow_count < fear_count then
            if ecs_single_entity.orientation == west then
              add(world, {
                actor = arrow,
                sprite = sprite_arrow_left,
                location = {ecs_single_entity.x_position - 1, ecs_single_entity.y_position},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = -0.4,
                y_movement = 0,
                has_collided = false,
                touched_who = nil
              })

            elseif ecs_single_entity.orientation == east then
              add(world, {
                actor = arrow,
                sprite = sprite_arrow_left,
                location = {ecs_single_entity.x_position + 1, ecs_single_entity.y_position},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0.4,
                y_movement = 0,
                has_collided = false,
                touched_who = nil
              })

            elseif ecs_single_entity.orientation == north then
              add(world, {
                actor = arrow,
                prite = sprite_arrow_left,
                location = {ecs_single_entity.x_position, ecs_single_entity.y_position - 1},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0,
                y_movement = -0.4,
                has_collided = false,
                touched_who = nil
              })

            elseif ecs_single_entity.orientation == south then
              add(world, {
                actor = arrow,
                sprite = sprite_arrow_left,
                location = {ecs_single_entity.x_position, ecs_single_entity.y_position + 1},
                x_position = location["1"],
                y_position = location["2"],
                x_movement = 0,
                y_movement = 0.4,
                has_collided = false,
                touched_who = nil
              })
            end
            arrow_count = arrow_count + 1
          end

        elseif ecs_single_entity.actor == disgust then
          if my_path:plain_queue_length() == 0 then
            local my_goal = dragon_location
            local seed = flr(rnd(3))

            if seed == 0 then
              my_goal["1"] = my_goal["1"] - 2
            elseif seed == 1 then
              my_goal["1"] = my_goal["1"] + 2
            elseif seed == 2 then
              my_goal["2"] = my_goal["2"] - 2
            else
              my_goal["2"] = my_goal["2"] + 2
            end

            my_path = astar_search(ecs_single_entity.location, my_goal)
          else
            ecs_single_entity.target = my_path:plain_queue_pop()
            move_opponent()
          end

        elseif ecs_single_entity.actor == anger or knight then
          if my_path:plain_queue_length() == 0 then
            my_path = astar_search(ecs_single_entity.location, dragon_location)

          else
            ecs_single_entity.target = my_path:plain_queue_pop()
            while ecs_single_entity.x_position ~= ecs_single_entity.x_goal
              and ecs_single_entity.y_position ~= ecs_single_entity.y_goal do

                if ecs_single_entity.touched_who < 1 then
                  if ecs_single_entity.x_position < ecs_single_entity.x_goal then
                    ecs_single_entity.x_movement = 0.2
                  elseif ecs_single_entity.x_position > ecs_single_entity.x_goal then
                    ecs_single_entity.x_movement = -0.2
                  end
                  if ecs_single_entity.y_position < ecs_single_entity.y_goal then
                    ecs_single_entity.y_movement = 0.2
                  elseif ecs_single_entity.y_position > ecs_single_entity.y_goal then
                    ecs_single_entity.y_movement = -0.2
                  end
                end

            end
          end
        end
      end
    end)


back_to_normal = function()
  if panic_phase == true then
    local calm_down = true

    for component_name, component_value in pairs(world) do
      if component_name == is_hunting then
        if component_value == true then
          calm_down = false
        end
      end
    end

    if calm_down == true then
      panic_phase = false
      music(music_gameplay)
    end
  end
end


fight_system = ecs_system({"actor", "x_location", "y_location"},
  function(ecs_single_entity)
    if ecs_single_entity.orientation == north then
      if {ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1}
      or {ecs_single_entity.x_location, ecs_single_entity.y_location - 1}
      or {ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1} == dragon_location then
        relocate_opponent_to_dragon()
      end
    elseif ecs_single_entity.orientation == south then
      if {ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1}
      or {ecs_single_entity.x_location, ecs_single_entity.y_location + 1}
      or {ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1} == dragon_location then
        relocate_opponent_to_dragon()
      end
    elseif ecs_single_entity.orientation == west then
      if {ecs_single_entity.x_location - 1, ecs_single_entity.y_location - 1}
      or {ecs_single_entity.x_location - 1, ecs_single_entity.y_location}
      or {ecs_single_entity.x_location - 1, ecs_single_entity.y_location + 1} == dragon_location then
        relocate_opponent_to_dragon()
      end
    elseif ecs_single_entity.orientation == east then
      if {ecs_single_entity.x_location + 1, ecs_single_entity.y_location - 1}
      or {ecs_single_entity.x_location + 1, ecs_single_entity.y_location}
      or {ecs_single_entity.x_location + 1, ecs_single_entity.y_location + 1} == dragon_location then
        relocate_opponent_to_dragon()
      end
    end

    if ecs_single_entity.actor == sadness then
      if ecs_single_entity.orientation == west or east then
        if {ecs_single_entity.x_location, ecs_single_entity.y_location - 1}
        or {ecs_single_entity.x_location, ecs_single_entity.y_location + 1} == dragon_location then
          relocate_opponent_to_dragon()
        end
      elseif ecs_single_entity.orientation == north or south then
        if {ecs_single_entity.x_location - 1, ecs_single_entity.y_location}
        or {ecs_single_entity.x_location + 1, ecs_single_entity.y_location} == dragon_location then
          relocate_opponent_to_dragon()
        end
      end

    elseif ecs_single_entity.actor == disgust then
      if ecs_single_entity.orientation == west then
        if {ecs_single_entity.x_location - 2, ecs_single_entity.y_location} then
          relocate_opponent_to_dragon()
          -- actually, disgust should stay in place with the lance touching the dragon.
        end
      elseif ecs_single_entity.orientation == east then
        if {ecs_single_entity.x_location + 2, ecs_single_entity.y_location} then
          relocate_opponent_to_dragon()
        end
      elseif ecs_single_entity.orientation == north then
        if {ecs_single_entity.x_location, ecs_single_entity.y_location - 2} then
          relocate_opponent_to_dragon()
        end
      elseif ecs_single_entity.orientation == south then
        if {ecs_single_entity.x_location, ecs_single_entity.y_location + 2} then
          relocate_opponent_to_dragon()
        end
      end

    end

  end)


relocate_opponent_to_dragon = function()
  ecs_single_entity.x_location = dragon_location["1"]
  ecs_single_entity.y_location = dragon_location["2"]
end


arrow_system = ecs_system({"actor", "touched_who", "has_collided"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == arrow
    and ecs_single_entity.has_collided == true then
      if ecs_single_entity.touched_who == flag_solidity
      or flag_solidity + flag_hurts_dragon + flag_is_fireproof then
        sfx(sound_effect_bump, 3)
      elseif ecs_single_entity.touched_who == flag_solidity + flag_hurts_dragon
      or flag_solidity + flag_hurts_subordinate then
        sfx(sound_effect_pierce, 3)
      end

      del(world, {location == ecs_single_entity.location})
      arrow_count = arrow_count - 1
    end
  end)


dynamite_system = ecs_system({"fuse_count", "touched_who", "has_collided"},
  function(ecs_single_entity)
    if ecs_single_entity.fuse_count > 0 then
      ecs_single_entity.fuse_count = ecs_single_entity.fuse_count - 1
    elseif fuse_count <= 0 then
      ecs_single_entity.sprite = sprite_dynamite_on
      sfx(sound_effect_explode, 3)
      for sentinel = 1, 3 do
        --nothing
      end

      del(world, {location == ecs_single_entity.location})
      dynamite_count = dynamite_count - 1
    end
  end)


draw_actor_system = ecs_system({"sprite", "x_location", "y_location"},
  function(ecs_single_entity)
    if title_phase and intermission_phase and setup_phase == false then
      spr(ecs_single_entity.sprite, ecs_single_entity.x_location, ecs_single_entity.y_location)
    end
  end)


did_that_hurt_system = ecs_system({"touched_who", "actor", "is_hurt"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == dragon then
      if ecs_single_entity.touched_who == flag_solidity + flag_hurts_dragon
      or flag_solidity + flag_hurts_dragon + flag_is_fireproof then
        ecs_single_entity.is_hurt = true
      end
    elseif ecs_single_entity.actor == joy
                                    or sadness
                                    or fear
                                    or disgust
                                    or anger
                                    or surprise then
      if ecs_single_entity.touched_who == flag_solidity + flag_hurts_subordinate then
        ecs_single_entity.is_hurt = true
      end
    end
  end)


attack_dragon_system = ecs_system({"location", "actor", "sprite", "orientation"},
  function(ecs_single_entity)
    if ecs_single_entity.location == dragon_location then
      if ecs_single_entity.actor == joy then
        ecs_single_entity.sprite = sprite_joy_attack
        sfx(sound_effect_bump, 3)
      elseif ecs_single_entity.actor == sadness then
        ecs_single_entity.sprite = sprite_sadness_attack
        sfx(sound_effect_slice, 3)
      elseif ecs_single_entity.actor == fear then
        ecs_single_entity.sprite = sprite_fear_attack
        sfx(sound_effect_explode, 3)
      elseif ecs_single_entity.actor == disgust then
        if ecs_single_entity.orientation == north or south then
          ecs_single_entity.sprite = sprite_disgust_attack_vertical
        else
          ecs_single_entity.sprite = sprite_disgust_attack_horizontal
        end
        sfx(sound_effect_pierce, 3)
      elseif ecs_single_entity.actor == anger then
        ecs_single_entity.sprite = sprite_anger_attack
        sfx(sound_effect_slice, 3)
      elseif ecs_single_entity.actor == surprise then
        ecs_single_entity.sprite = sprite_surprise_attack
        sfx(sound_effect_explode, 3)
      elseif ecs_single_entity.actor == knight then
        ecs_single_entity.sprite = sprite_knight_attack
        sfx(sound_effect_slice, 3)
      end

    end
  end)


lance_system = ecs_system({"sprite", "orientation", "x_location", "y_location"},
  function(ecs_single_entity)
    if ecs_single_entity.sprite == sprite_disgust_attack_horizontal then
      if ecs_single_entity.orientation == west then
        spr(sprite_lance_up, ecs_single_entity.x_location - 1, ecs_single_entity.y_location)
      elseif ecs_single_entity.orientation == east then
        spr(sprite_lance_up, ecs_single_entity.x_location + 1, ecs_single_entity.y_location)
      end
    elseif ecs_single_entity.sprite == sprite_disgust_attack_vertical then
      if ecs_single_entity.orientation == north then
        spr(sprite_lance_up, ecs_single_entity.x_location, ecs_single_entity.y_location - 1)
      elseif ecs_single_entity.orientation == south then
        spr(sprite_lance_up, ecs_single_entity.x_location, ecs_single_entity.y_location + 1)
      end
    end
  end)


embarrass_dragon_system = ecs_system({"actor", "is_hurt", "sprite"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == dragon and ecs_single_entity.is_hurt == true then
      normal_phase = false
      panic_phase = false
      music(-1)

      if ecs_single_entity.sprite == sprite_dragon_fly1_left or sprite_dragon_fly2_left or sprite_dragon_fire_left then
        ecs_single_entity.sprite = sprite_dragon_embarrassed_left
      end
      if ecs_single_entity.sprite == sprite_dragon_fly1_right or sprite_dragon_fly2_right or sprite_dragon_fire_right then
        ecs_single_entity.sprite = sprite_dragon_embarrassed_right
      end
      if ecs_single_entity.sprite == sprite_dragon_fly1_up or sprite_dragon_fly2_up or sprite_dragon_fire_up then
        ecs_single_entity.sprite = sprite_dragon_embarrassed_up
      end
      if ecs_single_entity.sprite == sprite_dragon_fly1_down or sprite_dragon_fly2_down or sprite_dragon_fire_down then
        ecs_single_entity.sprite = sprite_dragon_embarrassed_down
      end

      music(music_failure)
      repeat
        -- wait until the music is over
      until stat(16) == nil

      repeat
        ecs_single_entity.x_position = ecs_single_entity.x_position - 1
        ecs_single_entity.y_position = ecs_single_entity.y_position - 1
        sfx(sound_effect_retreat, 3)
      until ecs_single_entity.x_position < 0 and ecs_single_entity.y_position < 0

      if opportunities < 1 then
        lost_game()
      else
        previous_level = current_level
        cls()
        intermission_screen()
      end
    end
  end)


lost_game = function()
  print("game over", 50, 42)
  print("final round: "..(current_level + 1), 48, 84)
  print("press Ž", 50, 96)
  music(music_game_over)

  if btn(4) then
    cls()
    title_phase = true
    title_screen()
  end
end


hurt_subordinate_system = ecs_system({"is_hurt", "actor", "sprite",
                                  "x_location", "y_location", "location"},
  function(ecs_single_entity)
    if ecs_single_entity.is_hurt == true and ecs_single_entity.actor == joy
                                                                      or sadness
                                                                      or fear
                                                                      or disgust
                                                                      or anger
                                                                      or surprise then

      if ecs_single_entity.actor == joy then
        ecs_single_entity.sprite = sprite_joy_got_hurt
      elseif ecs_single_entity.actor == sadness then
        ecs_single_entity.sprite = sprite_sadness_got_hurt
      elseif ecs_single_entity.actor == fear then
        ecs_single_entity.sprite = sprite_fear_got_hurt
      elseif ecs_single_entity.actor == disgust then
        ecs_single_entity.sprite = sprite_disgust_got_hurt
      elseif ecs_single_entity.actor == anger then
        ecs_single_entity.sprite = sprite_anger_got_hurt
      elseif ecs_single_entity.actor == surprise then
        ecs_single_entity.sprite = sprite_surprise_got_hurt
      end

      for frame = 1, 4 do
        --nothing
      end

      sfx(sound_effect_warp, 3)
      for frame = 1, 8 do
        if frame % 2 == 1 then
          ecs_single_entity.sprite = sprite_warp1
        else
          ecs_single_entity.sprite = sprite_warp2
        end
      end

      del(world, {location == ecs_single_entity.location})
      if ecs_single_entity.actor == fear then
        fear_count = fear_count - 1
      elseif ecs_single_entity.actor == surprise then
        surprise_count = surprise_count - 1
      end
    end
  end)


treasure_system = ecs_system({"actor", "touched_who"},
  function(ecs_single_entity)
    if ecs_single_entity.actor == dragon
    and ecs_single_entity.touched_who == flag_solidity + flag_is_fireproof then
      got_treasure = true
      sfx(sound_effect_treasure, 3)
    end
  end)


won_stage = function()
  if dragon_location == {2, 1} and got_treasure == true then
    normal_phase = false
    panic_phase = false
    music(music_success)
    repeat
      -- wait until the music is over
    until stat(16) == nil

    current_level = current_level + 1
    if current_level > highest_round then
      highest_round = current_level
      dset(0, highest_round)
    end
    intermission_screen()
  end
end


--
--basic pico-8 stuff
--
function _init()
  cartdata("re_hoard_high_score")
  highest_round = dget(0)
  title_screen()
end

function _draw()
  draw_dungeon()
  draw_actor_system(world)
end

function _update()
  run_gameplay()
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
00000000000000000000000005050505010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000010000000100090101010b0b0b0b0b0b030303030303030303030303070707070303030303030303030303030303030303030303030303030303030303000107
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
01100000246500c653000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e6520e6520e6520e65200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002665026655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001175300700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

