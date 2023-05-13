SPATHS = {
  player: {
    flat: "sprites/cat.png",
    up: "sprites/cat-up.png",
    down: "sprites/cat-down.png",
  },
  bird: "sprites/bird.png",
  goal: "sprites/hexagon/black.png",
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
  title: "Tumbleweed goes to space",
  subtitle: "things could get hairy",
  instruction: "press SPACE to begin",
}

WIN_TEXTS = {
  title: "YOU MADE IT!",
  subtitle: "Tumbleweed went to space and got the thing",
  instruction: "press SPACE to start again",
}

ACCELERATION = 0.2
MAX_MOVE_SPEED = 12

class IntroScene
  attr_gtk

  def initialize texts
    @args = args
    @texts = texts
  end

  def setup
    t = @texts.instruction
    
    state.instruction_letters =
      t.chars.map.with_index(-t.length.half) do |l, i|
      {
        text: l,
        x: grid.center.x + i * 16,
        y: grid.center.y - 120 + i,
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
    state.instruction_letters.each do |l| 
      l.vel.y = (l.vel.y - 0.25)
                  .clamp(-12, 12)
      l.y += l.vel.y

      platform = grid.center.y - 130
      if l.y < platform
        l.y = platform
        l.vel.y = 4
      end
    end
    
    outputs.labels << [
      {
        text: @texts.title,
        x: grid.center.x,
        y: grid.center.y + 200,
        size_px: 64,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      },
      {
        text: @texts.subtitle,
        x: grid.center.x,
        y: grid.center.y + 120,
        size_px: 32,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      }]

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
    
    state.camera = 0
    
    state.player = {
      x: grid.center.x,
      y: 100,
      w: 128,
      h: 128,
      anchor_x: 0.5,
      anchor_y: 0,
      vel: {x: 0, y: 0,},
    }
    
    state.platforms = generate_level
    state.broken_platforms = []

    state.goal = {
      x: grid.center.x,
      y: state.platforms.last.y + 100,
      w: 80,
      h: 80,
      path: SPATHS.goal
    }

    audio[:theme] ||= {
      input: "sound/tumbleweed.ogg",
      looping: true,
    }
    
    @setup = true
  end

  def generate_level
    [
      {
        x: 0,
        y: 0,
        w: grid.w,
        h: 20
      },
      (1...50).map do |i|
        breakable = rand > 0.7
        vel = [0, 0, 0, 0, -1, 1].sample * (rand 4).to_i
        path = SPATHS.bird if (breakable && (vel != 0))
        {
          x: (rand grid.w),
          y: (i * 100) + rand(50),
          w: 200,
          h: 20,
          anchor_x: 0.5,
          anchor_y: 0.5,
          path: path,
          flip_horizontally: vel > 0,
          breakable: breakable,
          vel: { x: vel },
        }
      end
    ].flatten
  end

  def wraparound! entity
    if entity.right < 0
      entity.left = grid.w
    elsif entity.left > grid.w
      entity.right = 0
    end
  end

  def update
    state.game_paused = !state.game_paused if inputs.keyboard.key_down.escape
    state.game_paused = true if !inputs.keyboard.has_focus
    audio[:theme].paused = state.game_paused
    return if state.game_paused

    if inputs.keyboard.key_down.c
      state.selected_controls = state.controls.next
    end

    controls_settings = CONTROL_SETTINGS[state.selected_controls]
    
    state.camera = [player.y - 500, state.camera].max
    state.platforms.filter! do |p|
      p.top > state.camera
    end
    visible_platforms = state.platforms.filter do |p|
      p.bottom < state.camera + grid.h
    end
    
    lr = inputs.left_right.sign

    if state.selected_controls == :heavy
      player.x += player.vel.x      
    else
      player.x += lr * 10
    end

    # Find platforms that are below player before movement is applied
    visible_platforms.each do |p|
      if dx = p.vel&.x
        p.x += dx
        wraparound! p 
      end
    end
    
    below_platforms = visible_platforms.select { |c| player.bottom >= c.top}
    player.y += player.vel.y

    acc = ACCELERATION * lr
    # slow down faster than you speed up
    acc += ACCELERATION * lr if lr != player.vel.x.sign
    
    player.vel.x = (player.vel.x + acc)
                     .clamp(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)
    player.vel.y = (player.vel.y - controls_settings.gravity)
                     .clamp(-controls_settings.max_fall_speed, controls_settings.bounce_up_speed)

    # player.squish = (player.bounce_at.ease 15, :flip) if player.bounce_at else 0
    
    # wraparound
    wraparound! player
    
    # bounce up on collision
    plat = (geometry.find_intersect_rect player, below_platforms) if player.vel.y < 0
    if plat
      player.bottom = plat.top
      player.vel.y = controls_settings.bounce_up_speed
      player.bounce_at = state.tick_count
      
      if lr != 0 && lr != player.vel.x.sign
        player.vel.x = lr * 1.2
      end

      if plat.breakable
        state.platforms.delete plat
        state.broken_platforms << plat
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
      audio[:lose] = {
        input: "sound/lose.wav"
      }
      reset_level
    end

    # win
    if player.intersect_rect? state.goal
      audio[:win] = {
        input: "sound/win.wav"
      }
      @next_scene = IntroScene.new WIN_TEXTS
    end

    # One shots

    state.broken_platforms.each do |p|
      p.x += p.vel.x
      p.y -= 8
      if p.top < state.camera - 100 
        state.broken_platforms.delete p
      end
    end
  end

  def sprite_for_platform p
    p = p.dup
    p.y -= state.camera
    
    if p.path
      p.h = p.w
      p.sprite
    elsif p.breakable
      p.border
    else
      p.solid
    end
  end
  
  def render
    outputs.primitives << state.platforms.map do |p|
      sprite_for_platform p
    end
    outputs.primitives << state.broken_platforms.map do |p|
      p = sprite_for_platform p
      p.angle = 45 * (p.flip_horizontally ? -1 : 1)
      p
    end
    
    outputs.primitives << [state.goal].map do |p|
      p = p.dup
      p.h -= p.h.half * (p.squish || 0)
      p.y -= state.camera
      p.sprite
    end

    outputs.primitives << [player].map do |p|
      p = p.dup
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
    
    outputs.labels << {
      x: grid.w - 5,
      y: grid.h - 5,
      text: state.selected_controls,
      alignment_enum: 2,
      vertical_alignment_enum: 2,
    }

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
    update
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
  $scene = $scene.tick
end


$scene = IntroScene.new INTRO_TEXTS
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
