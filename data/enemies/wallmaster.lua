-- Falling hand that teleports the hero back to the entrance.
local enemy = ...
local map = enemy:get_map()

local sprite
local shadow_sprite
local shadow_xy

function enemy:on_created()

  enemy:set_life(1)
  enemy:set_damage(0)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_hurt_hero_running(true)
  enemy:set_layer_independent_collisions(true)
  enemy:set_invincible()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  sprite:set_animation("sleeping")
  shadow_sprite = sol.sprite.create("enemies/" .. enemy:get_breed())
  shadow_sprite:set_animation("shadow")
end

function enemy:on_restarted()

  sprite:set_animation("sleeping")
  shadow_xy = nil

  sol.timer.start(enemy, 5000, function()

    local distance = 240  -- Make sure that we start outside the visible screen.
    local hero = map:get_hero()
    local hero_x, hero_y = hero:get_position()
    enemy:set_position(hero_x, hero_y - distance, 2)
    shadow_xy = { hero_x, hero_y }

    -- Get down towards the hero.
    local movement = sol.movement.create("straight")
    movement:set_speed(192)
    movement:set_angle(3 * math.pi / 2)
    movement:set_ignore_obstacles(true)
    movement:set_max_distance(distance)
    movement:start(enemy)

    function movement:on_finished()
      sol.timer.start(enemy, 500, function()
        sprite:set_animation("closed")
      end)
    end

    sprite:set_animation("walking")
    
    sol.timer.start(enemy, 500, function()
      sol.audio.play_sound("jump")
    end)

    -- Go back.
    sol.timer.start(enemy, 3000, function()
      movement:set_angle(math.pi / 2)
      movement:set_speed(192)
      movement:start(enemy)
      function movement:on_finished()
        enemy:restart()
      end
    end)
  end)
end

-- Function called when overlapping the hero.
function enemy:on_attacking_hero(hero)

  local movement = enemy:get_movement()
  if movement ~= nil and movement:get_speed() ~= 0 then
    -- Currently moving: don't grab the hero now.
    return
  end

  if sprite:get_animation() ~= "closed" then
    -- Not the hand grabbing animation.
    return
  end

  if enemy:get_distance(hero) > 8 then
    -- The hero overlaps the hand but is still far enough from the center.
    return
  end

  -- Teleport the hero.
  -- TODO if teleporting to the same map, the map is not reset, take care of separator regions
  hero:freeze()
  hero:set_invincible(true, 500)
  sol.timer.start(hero, 500, function()
    sol.audio.play_sound("hero_hurt")
    hero:set_animation("hurt")
    local game = hero:get_game()
    hero:teleport(game:get_starting_location())

    -- When teleporting to the same room, restart the hand while the screen is black.
    sol.timer.start(game, 600, function()
      if enemy:exists() then
        enemy:restart()
      end
    end)
  end)
end

function enemy:on_pre_draw(dst_surface)

  if shadow_xy ~= nil then
    map:draw_sprite(shadow_sprite, shadow_xy[1], shadow_xy[2])
  end
end
