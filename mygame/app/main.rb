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

  def setup
    state.player ||= {
      x: grid.center.x,
      y: grid.h,
      w: 80,
      h: 80,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: SPATHS.player,
      
      vel: {x: 0, y: 0,},
    }
    
    state.platforms ||= [
      {
        x: 0,
        y: 0,
        w: grid.w,
        h: 20,
      },
      {
        x: 100,
        y: 200,
        w: 200,
        h: 20,
        anchor_x: 0.5,
        anchor_y: 0.5,
      },
      {
        x: grid.center.x,
        y: grid.center.y,
        w: 200,
        h: 20,
        anchor_x: 0.5,
        anchor_y: 0.5,
      }                   ]
  end

  def update
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
  end

  def render
    outputs.sprites << player
    outputs.solids << state.platforms
  end
  
  def tick
    setup
    update
    render
  end
end

$game ||= Game.new

def tick args
  $game.args = args
  $game.tick
end

$gtk.reset

