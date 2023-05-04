SPATHS = {
  player: "sprites/circle/black.png"
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
      w: 80,
      h: 80,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: SPATHS.player,
      
      vel: {x: 0, y: 0,},
    }
    
    state.platforms = generate_level
  end

  def generate_level
    [
      {
        x: 0,
        y: 0,
        w: grid.w,
        h: 20
      },
      (0...100).map do |i|
        {
          x: (rand grid.w),
          y: (rand grid.h / 3) + (i * 100),
          w: 200,
          h: 20,
          anchor_x: 0.5,
          anchor_y: 0.5,
        }
      end
    ].flatten
  end

  def update
    state.camera = [player.y - 500, state.camera].max
    player.x += player.vel.x.to_i
    player.y += player.vel.y.to_i
    
    player.vel.x = (player.vel.x + inputs.left_right * ACCELERATION)
                     .clamp(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)
    player.vel.y = (player.vel.y - GRAVITY)
                     .clamp(-MAX_FALL_SPEED, BOUNCE_UP_SPEED)
    
    # wraparound
    overlap = (player.w / 2).to_i
    if player.x < -overlap
      player.x = grid.w + overlap
    elsif player.x > grid.w + overlap
      player.x = -overlap
    end
    
    # bounce up on collision
    if (geometry.find_intersect_rect player, state.platforms)
      player.vel.y = BOUNCE_UP_SPEED
    end

    # death
    if player.y < state.camera
      reset_level
    end
  end

  def render
    outputs.sprites << [player].map do |p|
      p = p.dup
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

