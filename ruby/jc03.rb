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
  return Move.new(loc, target[:dir]) if target != nil && target[:site].strength < site.strength

  # wait to gather strength
  if site.strength < site.production*5
    return Move.new(loc, :still)
  end

  # lets go to the nearest border
  return Move.new(loc, nearest_border_direction(loc)) unless at_border(loc)

  # can't attack, hold still
  return Move.new(loc, :still)
end

def productive_target(site, loc)
  def evalutate(site)
    return site.production unless site.strength > 0
    return site.production / site.strength
  end

  GameMap::DIRECTIONS.map { |dir| {:dir => dir, :site => map.site(loc, dir)} }
  .select { |cell| cell[:site].owner != tag }
  .sort_by { |cell| -evalutate(cell[:site]) }
  .first
end

def nearest_border_direction(loc)
  direction = :north
  max_distance = [map.width, map.height].min / 2

  GameMap::DIRECTIONS.map do |dir|
    distance = 0
    current = loc
    site = map.site(current, dir)

    while(site.owner == tag && distance < max_distance)
      distance = distance + 1
      current = map.find_location(current, dir)
      site = map.site(current, dir)
    end

    if distance < max_distance
      direction = dir
      max_distance = distance
    end
  end

  direction
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
