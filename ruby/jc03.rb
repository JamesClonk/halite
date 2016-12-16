$:.unshift(File.dirname(__FILE__))
require 'networking'

$network, $tag, $map = nil

def network
  $network
end

def map
  $map
end

def tag
  $tag
end

def init
  $network = Networking.new("jc03_ruby")
  $tag, $map = network.configure
end

def update_game_map
  $map = network.frame
end

def move(site, loc)
  # go to productive targets first
  target = productive_target(site, loc)
  return Move.new(loc, target[:direction]) unless target.nil?

  # wait to gather strength
  if site.strength < site.production*5
    return Move.new(loc, :still)
  end

  # lets go to the nearest border
  return Move.new(loc, nearest_border_direction(loc)) unless at_border(loc)

  # can't attack, hold still
  return Move.new(loc, :still)
end

def evaluate_target(target)
  return (target.production*10.5) / (target.strength+0.5)
end

def productive_target(site, loc)
  GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir)} }
  .select { |cell| cell[:site].owner != tag && cell[:site].strength <= site.strength }
  .sort_by { |cell| -evaluate_target(cell[:site]) }
  .first
end

def nearest_border_direction(loc)
  max_distance = [map.width, map.height].min / 2
  directions = GameMap::DIRECTIONS.map do |direction|
    distance = 0
    current = loc
    site = map.site(current)

    while(site.owner == tag && distance < max_distance)
      distance = distance + 1
      current = map.find_location(current, direction)
      site = map.site(current)
    end

    {:distance => distance, :direction => direction, :site => site}
  end

  directions.sort_by { |cell| [cell[:distance], -cell[:site].production] }
  .first[:direction]
end

def at_border(loc)
  GameMap::DIRECTIONS.any? {|d| map.site(loc, d).owner != tag}
end

def main
  $network = Networking.new("jc03")
  $tag, $map = network.configure

  while true
    moves = []
    update_game_map

    (0...map.height).each do |y|
      (0...map.width).each do |x|
        loc = Location.new(x, y)
        site = map.site(loc)

        if site.owner == tag
          moves << move(site, loc)
        end
      end
    end

    network.send_moves(moves)
  end
end

main
