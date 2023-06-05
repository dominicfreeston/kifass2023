SPATHS = {
  player: {
    flat: "sprites/cat.png",
    up: "sprites/cat-up.png",
    down: "sprites/cat-down.png",
  },
  space: "sprites/space.png",
  transition: "sprites/skytransition.png",
  sky: "sprites/sky.png",
  tree: "sprites/tree.png",
  grass: "sprites/grass.png",
  branch1: {path: "sprites/branch1.png",
            w: 400,},
  branch2: {path: "sprites/branch2.png",
            w: 270,},
  bird: ["sprites/bird.png",
         "sprites/bird2.png"],
  cloud: [{path: "sprites/cloud1.png",
           w: 360,},
          {path: "sprites/cloud2.png",
           w: 460,},
          {path: "sprites/cloud3.png",
           w: 450,}],
  raincloud: [{path: "sprites/raincloud1.png",
               w: 450,},
              {path: "sprites/raincloud2.png",
               w: 460,},
              {path: "sprites/raincloud3.png",
               w: 360,}],
  balloon: ["sprites/balloon1.png",
            "sprites/balloon2.png",
            "sprites/balloon3.png",],
  goal: "sprites/yarn_ball.png",
  cutscene: ["sprites/cutscene1.png",
             "sprites/cutscene2.png",
             "sprites/cutscene3.png",
             "sprites/cutscene4.png",],
}

CONTROL_SETTINGS = {
  heavy: {
    gravity: 0.5,
    max_fall_speed: 12,
    bounce_up_speed: 16,
  },
  fast: {
    gravity: 1,
    max_fall_speed: 16,
    bounce_up_speed: 24,
  }
}

INTRO_TEXTS = {
  title: "Hey, that's my yarn!",
  subtitle: "a game made with DragonRuby for the KIFASS game jam",
  credits: [
    ["programming and design", "Dominic Freeston"],
    ["concept and art", " Ellis"],
    ["with music by", "Ryan Edgewurth"],
  ],
  instruction: "press SPACE to begin",
  background: SPATHS.sky,
  text_color: {r: 0, g: 0, b: 64},
}

WIN_TEXTS = {
  title: "YOU MADE IT!",
  subtitle: "You went all the way to space and got the yarn.",
  instruction: "press SPACE to start again",
  background: SPATHS.space,
  text_color: {r: 255, g: 255, b: 255},
}

ACCELERATION = 0.2
MAX_MOVE_SPEED = 12

class CutScene
  attr_gtk

  def initialize
    @screens = SPATHS.cutscene
    @current = 0
    @next = 1
  end
  
  def tick
    @current_started_at ||= state.tick_count

    progress = (@current_started_at + 2.seconds).ease 1.seconds, :cube
    
    wipe progress

    if progress >= 1 || inputs.keyboard.key_down.space
      if @next >= @screens.length
        return IntroScene.new INTRO_TEXTS
      end  

      @current = @next
      @next += 1
      @current_started_at = state.tick_count
    end

    self
  end

  def wipe progress
    outputs.sprites << {
      x: 0,
      y: 0,
      w: grid.w,
      h: grid.h,
      path: @screens[@next]
    }

    path = @screens[@current]

    w = 10
    move = ((grid.w + w) * progress).to_i
    outputs.sprites << {
      x: 0,
      y: 0,
      w: grid.w - move,
      h: grid.h,
      path: path,
      source_x: 0,
      source_w: grid.w - move,
    }

    outputs.primitives << {
      x: grid.w - move,
      y: 0,
      w: w,
      h: grid.h,
    }.solid
  end
  
  def split progress
    outputs.sprites << {
      x: 0,
      y: 0,
      w: grid.w,
      h: grid.h,
      path: @screens[@next]
    }

    path = @screens[@current]
    left = {
      x: 0 - (grid.w / 2) * progress,
      y: 0,
      w: grid.w / 2,
      h: grid.h,
      path: path,
      source_x: 0,
      source_w: grid.w / 2,
    }
    right = {
      x: grid.center.x + (grid.w / 2) * progress,
      y: 0,
      w: grid.w / 2,
      h: grid.h,
      path: path,
      source_x: grid.center.x,
      source_w: grid.w / 2,
    }

    outputs.sprites << [left, right]
  end
end

class IntroScene
  attr_gtk

  def initialize texts
    @args = args
    @texts = texts
  end

  def setup
    @offset = -100
    t = @texts.instruction
    
    state.instruction_letters =
      t.chars.map.with_index(-t.length.half) do |l, i|
      {
        text: l,
        x: grid.center.x + i * 16,
        y: grid.center.y + @offset + t.length.half + i,
        size_px: 32,
        alignment_enum: 0,
        vertical_alignment_enum: 1,
        vel: {x: 0, y: 0,},
      }  
    end
    
    @setup = true
  end
  
  def tick
    setup if not @setup

    text_color = @texts.text_color
    
    state.instruction_letters.each do |l|
      l.merge! text_color
      l.vel.y = (l.vel.y - 0.25)
                  .clamp(-12, 12)
      l.y += l.vel.y

      platform = grid.center.y + @offset
      if l.y < platform
        l.y = platform
        l.vel.y = 4
      end
    end

    outputs.sprites << {
      x: 0, y: 0, w: 1280, h: 720,
      path: @texts.background
    }
    
    outputs.labels << [
      {
        text: @texts.title,
        x: grid.center.x,
        y: grid.center.y + 200,
        size_px: 64,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      }.merge(text_color),
      {
        text: @texts.subtitle,
        x: grid.center.x,
        y: grid.center.y + 120,
        size_px: 32,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      }.merge(text_color),
    ]
    
    outputs.sprites << [
      {
        x: grid.center.x,
        y: grid.center.y + 80,
        w: 128,
        h: 128,
        path: SPATHS.player.flat,
        anchor_x: 1,
        anchor_y: 1,
      },
      {
        x: grid.center.x,
        y: grid.center.y + 80,
        w: 128,
        h: 128,
        path: SPATHS.goal,
        anchor_x: 0,
        anchor_y: 1,
      },
    ] if @texts.credits
    
    outputs.labels << @texts.credits.map.with_index(- @texts.credits.length.idiv(2)) do |text, i|
      r1 = layout.rect row: 10, col: 12 + i * 8, w: 0, h: 0
      r2 = layout.rect row: 11, col: 12 + i * 8, w: 0, h: 0

      [{
         **r1,
         text: text[0],
         alignment_enum: 1
       }.merge(text_color),
       {
         **r2,
         size_px: 32,
         text: text[1],
         alignment_enum: 1
       }.merge(text_color)
      ]
    end if @texts.credits

    outputs.labels << state.instruction_letters

    start_game_pressed ? Game.new : self
  end

  def start_game_pressed
    inputs.keyboard.key_down.space
  end
  
end

class Game
  attr_gtk

  def player
    state.player
  end

  def reset_level
    state.game_paused ||= false
    state.controls ||= [:heavy, :fast].cycle
    state.selected_controls ||= state.controls.next

    state.camera_drop_vel = 0
    state.drop_start = state.tick_count
    state.intro_drop = true
    state.camera_goal = 0
    
    state.player = {
      x: 100,
      y: 0,
      w: 64,
      h: 64,
      anchor_x: 0.5,
      anchor_y: 0,
      vel: {x: 0, y: CONTROL_SETTINGS.heavy.bounce_up_speed,},
    }

    state.platforms = generate_platforms

    # clean up level, stopping power_ups from intersecting
    
    power_ups = state.platforms.filter do |p|
      p.power_up
    end.map do |p|
      p = p.dup
      p.h = 100
      p.anchor_y = 0
      p
    end

    state.platforms.filter! do |p|
      p.power_up || (not geometry.find_intersect_rect p, power_ups)
    end
    
    state.broken_platforms = []
    
    state.goal = {
      x: grid.center.x,
      y: state.platforms.last.y + 300,
      w: 256,
      h: 256,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: SPATHS.goal
    }

    state.camera = state.goal.y - 360

    audio[:theme] ||= {
      input: "sound/tumbleweed.ogg",
      looping: true,
    }
    
    @setup = true
  end

  def generate_platforms
    [
      # floor
      {
        x: 0,
        y: 0,
        w: grid.w,
        h: 20
      },
      # starting tree branches
      (2...10).map do |i|
        branch = [SPATHS.branch1, SPATHS.branch2].sample
        {
          x: grid.center.x,
          y: (i * 100) + rand(30),
          w: branch.w,
          h: 20,
          anchor_x: i % 2,
          anchor_y: 0.5,
          path: branch.path,
          flip_horizontally: i % 2 != 0,
          sprite_scale: 512 / branch.w,
        }
      end,
      # rest of level
      (1...50).map do |i|
        breakable = rand > 0.7
        vel = [0, 0, 0, 0, -1, 1].sample * (rand 4).to_i
        w = 200
        h = 20

        full_sprite = false
        power_up = (!breakable) && (vel == 0) && (rand > 0.8)

        sprite_scale = 1
        if power_up
          full_sprite = true
          path = SPATHS.balloon.sample
          w = 100
          h = 60
          sprite_scale = 512 / 200
        elsif breakable
          if (vel == 0)
            cloud = SPATHS.raincloud.sample
            path = cloud.path
            sprite_scale = 512 / cloud.w
          else
            sprites = SPATHS.bird
          end
        else
          cloud = SPATHS.cloud.sample
          path = cloud.path
          sprite_scale = 512 / cloud.w
        end
        
        {
          x: (rand grid.w),
          y: 950 + (i * 100) + rand(50),
          w: w,
          h: h,
          anchor_x: 0.5,
          anchor_y: 0.5,
          path: path,
          sprites: sprites,
          flip_horizontally: vel > 0,
          breakable: breakable,
          vel: { x: vel },
          full_sprite: full_sprite,
          power_up: power_up,
          sprite_scale: sprite_scale,
        }
      end,
    ].flatten
  end

  def wraparound! entity
    if entity.right < 0
      entity.left = grid.w
    elsif entity.left > grid.w
      entity.right = 0
    end
  end

  def update_drop

    if inputs.keyboard.key_down.space
      state.intro_drop = false
      state.camera = 0 
      return
    end
    
    wait_time = 1.seconds
    wait_progress = state.drop_start.ease wait_time

    return if wait_progress < 1
    
    accelerate_ramp = (state.drop_start + wait_time).ease 2.seconds
    camera_delta = (state.camera_goal - state.camera)
    state.camera_drop_vel = (state.camera_drop_vel + accelerate_ramp).clamp(0, 30)
    
    state.camera += camera_delta.sign * [camera_delta.abs, state.camera_drop_vel].min
    state.camera = state.camera.floor

    state.intro_drop = false if state.camera < 720
  end
  
  def update
    state.game_paused = !state.game_paused if inputs.keyboard.key_down.escape
    state.game_paused = false if inputs.keyboard.key_down.space
    state.game_paused = true if !inputs.keyboard.has_focus
    audio[:theme].paused = state.game_paused

    return if state.game_paused

    # if inputs.keyboard.key_down.c
    #   state.selected_controls = state.controls.next
    # end

    
    gtk.slowmo! 4 if (geometry.distance player, state.goal) < 300
    
    controls_settings = CONTROL_SETTINGS[state.selected_controls]

    camera_delta = (state.camera_goal - state.camera)
    camera_vel = camera_delta.positive? ? 20 : 30
    camera_vel = 80 if (state.goal.y - player.y).abs < 300
    state.camera += camera_delta.sign * [camera_delta.abs, camera_vel].min

    if state.player.vel.y > 0
      state.camera_goal = [player.y - 500, state.camera_goal].max
    end
    
    # state.platforms.filter! do |p|
    #  p.top > state.camera - 1000
    # end
    
    visible_platforms = state.platforms.filter do |p|
      p.bottom < state.camera + grid.h
    end
    
    lr = inputs.left_right.sign

    if state.selected_controls == :heavy
      player.x += player.vel.x      
    else
      player.x += lr * 10
    end

    visible_platforms.each do |p|
      if dx = p.vel&.x
        p.x += dx
        wraparound! p 
      end
    end
    
    below_platforms = visible_platforms.select { |c| player.bottom >= c.top}
    player.y += player.vel.y

    # player.vel.x = 0 if lr != 0 && lr != player.vel.x.sign
    acc = ACCELERATION * lr
    # slow down faster than you speed up
    acc += ACCELERATION * lr * 2 if lr != player.vel.x.sign

    player.vel.x = (player.vel.x + acc)
                     .clamp(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)
    player.vel.y = (player.vel.y - controls_settings.gravity)
                     .clamp(-controls_settings.max_fall_speed, controls_settings.bounce_up_speed * 4)

    # player.squish = (player.bounce_at.ease 15, :flip) if player.bounce_at else 0
    
    # wraparound
    wraparound! player
    
    # bounce up on collision
    plat = (geometry.find_intersect_rect player, below_platforms) if player.vel.y < 0
    if plat
      player.bottom = plat.top
      player.vel.y = controls_settings.bounce_up_speed

      if plat.power_up
        player.vel.y += controls_settings.bounce_up_speed
        audio[:powerup] ||= {
          input: "sound/powerup.wav"
        }
      end
      player.bounce_at = state.tick_count
      
      if lr != 0 && lr != player.vel.x.sign
        player.vel.x = lr * 1.2
      end

      if plat.breakable
        state.platforms.delete plat
        if plat.vel.x != 0
          plat.vel.y = -8
          state.broken_platforms << plat
        else
          ## Rain
          p = plat
          state.broken_platforms += (-32...32).map do |i|
            {
              x: p.x,
              y: p.y - 20 * rand,
              w: 2,
              h: 3,
              anchor_x: 0.5,
              anchor_y: 0.5,
              r: 0,
              g: 0,
              b: 55,
              vel: {x: -2 + rand * 4, y: -4 - rand * 4},
              rain: true,
            }
          end
        end
        audio[:break] ||= {
          input: "sound/break.wav",
          gain: 0.5,
          pitch: 0.9 + (rand 0.2),
        }
      end

      audio[:jump] ||= {
        input: "sound/jump.wav"
      }
    end

    # lose
    if player.top < state.camera
      if player.bottom > 700 && player.top < state.goal.bottom
        audio[:lose] = {
          input: "sound/lose.wav"
        }
        reset_level
      else
        state.camera_goal = [player.y - 1000, 0].max
      end
    end

    # win
    if player.intersect_rect? state.goal
      audio[:win] = {
        input: "sound/fanfare.ogg"
      }
      @next_scene = IntroScene.new WIN_TEXTS
    end

    # One shots

    state.broken_platforms.each do |p|
      p.x += p.vel.x
      p.y += p.vel.y
      if p.top < state.camera - 100 
        state.broken_platforms.delete p
      end
    end
  end

  def sprite_for_platform p
    p = p.dup
    p.y -= state.camera
    
    if p.path
      p.w = p.w * (p.sprite_scale || 1)
      p.h = p.w
      p.sprite
    elsif p.sprites
      # this is just birds in the end
      p.h = p.w
      s = p.sprites
      loc = (p.x.idiv 50) % 2
      p.path = s[loc]
      p.sprite
    elsif p.breakable
      p.border
    else
      nil
    end
  end
  
  def render
    sky_start = state.goal.y - 2000
    
    outputs.primitives << [
      #sky
      {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        path: SPATHS.sky,
      }.sprite,
      # transition
      {
        x: 0,
        y: [sky_start - 720 - state.camera, - 720].max,
        w: 1280,
        h: 720,
        path: SPATHS.transition,
      }.sprite,
      # space
      {
        x: 0,
        y: [sky_start - state.camera, 0].max,
        w: 1280,
        h: 720,
        path: SPATHS.space
      }.sprite,
      # tree-trunk
      {
        x: grid.center.x,
        y: -state.camera,
        w: 794 * 2,
        h: 894 * 2,
        anchor_x: 0.5,
        anchor_y: 0,
        path: SPATHS.tree,
      }.sprite,
      # grass
      {
        x: 0,
        y: -state.camera,
        w: 1280,
        h: 165,
        path: SPATHS.grass,
      }.sprite,
    ]
    
    # platforms
    outputs.primitives << state.platforms.map do |p|
      sprite_for_platform p
    end
    
    outputs.primitives << state.broken_platforms.map do |p|
      if p.rain
        ## Rain
        p = p.dup
        p.y -= state.camera
        p.solid
      else
        ## Bird
        p = sprite_for_platform p
        p.angle = 45 * (p.flip_horizontally ? -1 : 1)
        p
      end
    end

    outputs.primitives << [state.goal].map do |p|
      p = p.dup
      p.h -= p.h.half * (p.squish || 0)
      p.y -= state.camera
      p.sprite
    end

    outputs.primitives << [player].map do |p|
      p = p.dup
      p.w = 128
      p.h = 128
      p.y -= state.camera
      delta = 2
      if p.vel.y > delta
        p.path = SPATHS.player.up
      elsif p.vel.y < -delta
        p.path = SPATHS.player.down
      else
        p.path = SPATHS.player.flat
      end
      p.flip_horizontally = p.vel.x < 0
      p.sprite
    end

    if state.debug_on
      outputs.primitives << state.platforms.map do |p|
        p = p.dup
        p.y -= state.camera
        p.border
      end

      outputs.primitives << state.pla

      outputs.primitives << [player].map do |p|
        p = p.dup
        p.y -= state.camera
        p.border
      end
    end
    
    if state.game_paused
      outputs.primitives << [1, 2].map do |n|
        {
          x: n * 20,
          y: grid.h - 20,
          w: 10,
          h: 40,
          anchor_x: 0,
          anchor_y: 1,
        }.solid
      end
    end
  end
  
  def tick
    reset_level if !@setup

    if state.intro_drop
      update_drop
    else
      update
    end
    
    render

    # debug overlay
    state.debug_on ||= false
    if inputs.keyboard.key_down.p
      state.debug_on = !state.debug_on
    end
    if state.debug_on
      outputs.debug << gtk.framerate_diagnostics_primitives
    end

    
    audio[:theme] = nil if @next_scene
    @next_scene || self
  end
end

def tick args
  args.outputs.background_color = [0, 0, 0]
  args.outputs.solids << [0, 0, args.grid.w, args.grid.h, 255, 255, 255]

  $scene.args = args
  # I have regrets about this whole
  # always return the next tick scene thing.
  # It keeps tripping me up!
  $scene = $scene.tick
end


$scene = IntroScene.new INTRO_TEXTS
# $scene = CutScene.new
# $scene = Game.new
$gtk.reset

## This is probably a bad idea but let's try it for this game!
module AttrRectExtended
  def left
    x - w * (anchor_x || 0)
  end
  
  def right
    x + w * (1 - (anchor_x || 0))
  end
  
  def bottom
    y - h * (anchor_y || 0)
  end

  def top
    y + h * (1 - (anchor_y || 0))
  end

  def left= v
    self.x = v + w * (anchor_x || 0)
  end
  
  def right= v
    self.x = v - w * (1 - (anchor_x || 0))
  end

  def bottom= v
    self.y = v + h * (anchor_y || 0)
  end

  def top= v
    self.y = v - h * (1 - (anchor_y || 0))
  end
end

class Hash
  prepend AttrRectExtended
end
