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
  return Move.new(loc, target[:direction]) if target[:attack]

  # wait to gather strength
  if site.strength < site.production*5
    return Move.new(loc, :still)
  end

  # does a cell around me need help?
  help = help_strength(site, loc)
  return Move.new(loc, help[:direction]) if help[:help]

  # lets go to the nearest border
  return Move.new(loc, nearest_border_direction(loc)) unless at_border(loc)

  # can't attack, hold still
  return Move.new(loc, :still)
end

def evaluate_target(target)
  return (target.production*1.0) unless target.strength > 0
  return (target.production*1.0) / (target.strength*1.0)
end

def productive_target(site, loc)
  target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir)} }
  .select { |cell| cell[:site].owner != tag }
  .sort_by { |cell| -evaluate_target(cell[:site]) }
  .first

  return {:attack => false} if target.nil?

  if target[:site].strength > site.strength ||
    (target[:site].strength == site.strength && site.strength < 250)
    return {:attack => false}
  end
  return {:attack => true, :direction => target[:direction], :site => target[:site]}
end

# def help_production(site, loc)
#   target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir)} }
#   .select { |cell|
#     cell[:site].owner == tag &&
#     cell[:site].production > site.production && # go to higher production location
#     cell[:site].strength+site.strength <= 260 &&
#     at_border(map.find_location(loc, cell[:direction])) }
#   .sort_by { |cell| -cell[:site].production }
#   .first

#   return {:help => false} if target.nil?
#   return {:help => true, :direction => target[:direction], :site => target[:site]}
# end

def help_strength(site, loc)
  target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir)} }
  .select { |cell|
    cell[:site].owner == tag &&
    cell[:site].strength > site.strength && # weaker cells should reinforce stronger ones
    cell[:site].strength+site.strength <= 260 &&
    at_border(map.find_location(loc, cell[:direction])) }
  .sort_by { |cell| -cell[:site].production }
  .first

  return {:help => false} if target.nil?
  return {:help => true, :direction => target[:direction], :site => target[:site]}
end

def nearest_border_direction(loc)
  max_distance = [map.width, map.height].min / 2

  GameMap::DIRECTIONS.map do |direction|
    distance = 0
    current = loc
    site = map.site(current, direction)

    while(site.owner == tag && distance < max_distance)
      distance = distance + 1
      current = map.find_location(current, direction)
      site = map.site(current)
    end

    {:distance => distance, :direction => direction, :site => site}
  end
  .sort_by { |cell| [cell[:distance], -cell[:site].production] }
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
