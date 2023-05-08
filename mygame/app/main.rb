SPATHS = {
  player: "sprites/circle/black.png",
  goal: "sprites/hexagon/black.png",
}

GRAVITY = 0.25
MAX_FALL_SPEED = 12
BOUNCE_UP_SPEED = 12

ACCELERATION = 0.1
MAX_MOVE_SPEED = 12

class IntroScene
  attr_gtk

  def tick
    title = "Tumbleweed goes to space"
    subtitle = "things could get hairy"
    instruction = "press any key to begin"
    
    state.instruction_letters ||=
    instruction.chars.map.with_index(-instruction.length.half) do |l, i|
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

    state.instruction_letters.each do |l| 
      l.vel.y = (l.vel.y - GRAVITY)
                  .clamp(-MAX_FALL_SPEED, BOUNCE_UP_SPEED)
      l.y += l.vel.y

      platform = grid.center.y - 130
      if l.y < platform
        l.y = platform
        l.vel.y = 4
      end
    end
    
    outputs.labels << [
      {
        text: title,
        x: grid.center.x,
        y: grid.center.y + 200,
        size_px: 64,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      },
      {
        text: subtitle,
        x: grid.center.x,
        y: grid.center.y + 120,
        size_px: 32,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
      }]

    outputs.labels << state.instruction_letters

    any_key_pressed ? Game.new : self
  end

  def any_key_pressed
    (inputs.keyboard.key_down.truthy_keys.length || 0) > 0
  end
  
end

class Game
  attr_gtk

  def player
    state.player
  end

  def reset_level
    state.camera = 0
    
    state.player = {
      x: grid.center.x,
      y: 100,
      w: 128,
      h: 128,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: SPATHS.player,
      vel: {x: 0, y: 0,},
    }
    
    state.platforms = generate_level

    state.goal = {
      x: grid.center.x,
      y: state.platforms.last.y + 100,
      w: 80,
      h: 80,
      path: SPATHS.goal
    }

    audio[:theme] = {
      input: "music/tumbleweed.ogg",
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
        {
          x: (rand grid.w),
          y: (i * 100) + rand(50),
          w: 200,
          h: 20,
          anchor_x: 0.5,
          anchor_y: 0.5,
        }
      end
    ].flatten
  end

  def update
    if !inputs.keyboard.has_focus
      return
    end
    
    state.camera = [player.y - 500, state.camera].max
    state.platforms.filter! do |p|
      p.top > state.camera
    end
    
    player.x += player.vel.x
    player.y += player.vel.y

    lr = inputs.left_right.sign
    acc = ACCELERATION * lr
    # slow down faster than you speed up
    acc += ACCELERATION * lr if lr != player.vel.x.sign
    
    player.vel.x = (player.vel.x + acc)
                     .clamp(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)
    player.vel.y = (player.vel.y - GRAVITY)
                     .clamp(-MAX_FALL_SPEED, BOUNCE_UP_SPEED)

    player.squish = (player.bounce_at.ease 15, :flip) if player.bounce_at else 0
    
    # wraparound
    if player.right < 0
      player.left = grid.w
    elsif player.left > grid.w
      player.right = 0
    end
    
    # bounce up on collision
    collisions = (geometry.find_all_intersect_rect player, state.platforms) if player.vel.y < 0
    if collisions&.any? { |c| player.y > c.top}
      player.vel.y = BOUNCE_UP_SPEED
      player.bounce_at = state.tick_count
      if lr != 0 && lr != player.vel.x.sign
        player.vel.x = lr * 1.2
      end
    end

    # lose
    if player.top < state.camera
      reset_level
    end

    # win
    if player.intersect_rect? state.goal
      reset_level
    end
  end

  def render    
    outputs.sprites << [player, state.goal].map do |p|
      p = p.dup
      p.h -= p.h.third * (p.squish || 0)
      p.y -= state.camera
      p
    end
    outputs.solids << state.platforms.map do |p|
      p = p.dup
      p.y -= state.camera
      p
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

    self
  end
end

def tick args
  args.outputs.background_color = [0, 0, 0]
  args.outputs.solids << [0, 0, args.grid.w, args.grid.h, 255, 255, 255]

  $scene.args = args
  $scene = $scene.tick
end


$scene = IntroScene.new
$gtk.reset


## This is probably a bad idea but let's try it for this game!
class Hash
  def left
    self[:left] || (x - w * (anchor_x || 0) if is_rect?)
  end

  def left= v
    if is_rect? && !(key? :left)
      self.x = v + w * (anchor_x || 0)
    else
      self[:left] = v
    end
  end
    
  def right
    self[:right] || (x + w * (1 - (anchor_x || 0)) if is_rect?)
  end

  def right= v
    if is_rect? && !(key? :right)
      self.x = v - w * (1 - (anchor_x || 0))
    else
      self[:right] = v
    end
  end

  def top
    self[:top] || (y + h * (1 - (anchor_y || 0)) if is_rect?)
  end

  def top= v
    if is_rect? && !(key? :top)
      self.x = v - h * (1 - (anchor_y || 0))
    else
      self[:top] = v
    end
  end
  
  def bottom
    self[:bottom] || (y - h * (anchor_y || 0) if is_rect?)
  end

  def bottom= v
    if is_rect? && !(key? :bottom)
      self.x = v + h * (anchor_y || 0)
    else
      self[:bottom] = v
    end
  end

  def is_rect?
    %i[x y w h].all? { |s| key? s }
  end
end

