SPATHS = {
  player: "sprites/circle/black.png",
  goal: "sprites/hexagon/black.png",
}

GRAVITY = 0.25
MAX_FALL_SPEED = 12
BOUNCE_UP_SPEED = 12

ACCELERATION = 0.1
MAX_MOVE_SPEED = 12

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
    if !args.inputs.keyboard.has_focus
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
    outputs.background_color = [0, 0, 0]
    outputs.solids << [0, 0, grid.w, grid.h, 255, 255, 255]
    
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
    reset_level if state.tick_count == 0
    update
    render

    # debug overlay
    args.state.debug_on ||= false
    if args.inputs.keyboard.key_down.p
      args.state.debug_on = !args.state.debug_on
    end
    if args.state.debug_on
      args.outputs.debug << args.gtk.framerate_diagnostics_primitives
    end

  end
end

$game ||= Game.new

def tick args
  $game.args = args
  $game.tick
end

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

