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
      w: 80,
      h: 80,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: SPATHS.player,
      angle: -90,
      
      vel: {x: 0, y: 0,},
    }
    
    state.platforms = generate_level

    state.goal = {
      x: grid.center.x,
      y: state.platforms.last.y + 100,
      w: 80,
      h: 80,
      angle: 90,
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
      (0...50).map do |i|
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

    player.w = (40 + (player.bounce_at.ease 15) * 40).to_i if player.bounce_at
    
    # wraparound
    overlap = (player.w / 2).to_i
    if player.x < -overlap
      player.x = grid.w + overlap
    elsif player.x > grid.w + overlap
      player.x = -overlap
    end
    
    # bounce up on collision
    if (player.vel.y < 0) && (geometry.find_intersect_rect player, state.platforms)
      player.vel.y = BOUNCE_UP_SPEED
      player.bounce_at = state.tick_count
      if lr != 0 && lr != player.vel.x.sign
        player.vel.x = lr * 1.2
      end
    end

    # lose
    if player.y < state.camera
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

