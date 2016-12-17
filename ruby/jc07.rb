require 'set'
$:.unshift(File.dirname(__FILE__))
require 'networking'

$network, $tag, $map, $territory, $enemies = nil

def network
  $network
end

def map
  $map
end

def tag
  $tag
end

def territory
  $territory
end

def enemies
  $enemies
end

def init
  $network = Networking.new("jc07")
  $tag, $map = network.configure
end

def update_game
  $map = network.frame

  owners = Set.new
  count = 0

  (0...map.height).each do |y|
    (0...map.width).each do |x|
      owner = map.site(Location.new(x, y)).owner
      if owner == tag
        count += 1
      elsif owner != 0
        owners << owner
      end
    end
  end

  $territory = count
  $enemies = owners.to_a
end

def move(site, loc)
  # go to productive targets first
  target = productive_target(site, loc)
  return Move.new(loc, target[:direction]) if target[:attack]

  # wait to gather more strength
  return nil if needs_more_strength?(site)

  # lets go to the nearest border
  if !at_border?(loc)
    border_dir = nearest_border_direction(loc)
    return Move.new(loc, border_dir) if allow_move?(site, loc, border_dir)
  end

  # does a cell around me need help?
  help = help_strength(site, loc)
  return Move.new(loc, help[:direction]) if help[:help]
  help = help_production(site, loc)
  return Move.new(loc, help[:direction]) if help[:help]

  # can't attack, hold still
  return nil
end

def needs_more_strength?(site)
  factor = 5.0
  e = 1.0 / [enemies.size, 2].min
  if territory > e * (1.0 * map.height * map.width / 3.0)
    factor = e * (1.0 * map.height * map.width / territory) + 1.5
    if factor > 5.0
      factor = 5.0
    end
  end
  return site.strength < site.production*factor
end

def allow_move?(site, loc, dir)
  target = map.site(loc, dir)
  if target.owner == tag
    site.strength + target.strength <= 260
  end
  return target.strength <= site.strength
end

def evaluate_target(target)
  return (target[:site].production*1.0) unless target[:site].strength > 0
  return (target[:site].production*1.0) / (target[:site].strength*1.0)
end

def productive_target(site, loc)
  target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir), :location => map.find_location(loc, dir)} }
  .select { |cell| cell[:site].owner != tag }
  .sort_by { |cell| -evaluate_target(cell) }
  .first

  return {:attack => false} if target.nil?

  if target[:site].strength > site.strength ||
    (target[:site].strength == site.strength && site.strength < 250)
    return {:attack => false}
  end
  return {:attack => true, :direction => target[:direction], :site => target[:site]}
end

def help_production(site, loc)
  target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir), :location => map.find_location(loc, dir)} }
  .select { |cell|
    cell[:site].owner == tag &&
    cell[:site].production > site.production && # go to higher production location
    cell[:site].strength+site.strength <= 260 &&
    at_border?(cell[:location]) } # only help cells which are at a border, not "inland"
  .sort_by { |cell| -cell[:site].production }
  .first

  return {:help => false} if target.nil?
  return {:help => true, :direction => target[:direction], :site => target[:site]}
end

def help_strength(site, loc)
  target = GameMap::DIRECTIONS.map { |dir| {:direction => dir, :site => map.site(loc, dir), :location => map.find_location(loc, dir)} }
  .select { |cell|
    cell[:site].owner == tag &&
    cell[:site].strength > site.strength && # weaker cells should reinforce stronger ones
    cell[:site].strength+site.strength <= 260 &&
    at_border?(cell[:location]) } # only help cells which are at a border, not "inland"
  .sort_by { |cell| -cell[:site].production }
  .first

  return {:help => false} if target.nil?
  return {:help => true, :direction => target[:direction], :site => target[:site]}
end

def most_productive_border_direction(loc)
  max_distance = [map.width, map.height].min / 2

  GameMap::DIRECTIONS.map do |direction|
    distance = 0
    current = loc
    site = map.site(current, direction)

    # maybe find alternative route if we can't move in this direction anyway?
    if site.strength + map.site(loc).strength > 260
      distance += 1
    end

    while(site.owner == tag && distance < max_distance)
      distance += 1
      current = map.find_location(current, direction)
      site = map.site(current)
    end

    {:distance => distance, :direction => direction, :site => site, :location => current}
  end
  .sort_by { |cell| -(evaluate_production(cell) / cell[:distance]) }
  .first[:direction]
end

def evaluate_production(cell)
  production = 0.5
  if cell[:site].owner != tag
    production += cell[:site].production
  end
  GameMap::DIRECTIONS.each do |direction|
    site = map.site(cell[:location], direction)
    if site.owner != tag
      production += map.site(cell[:location], direction).production
    end
  end
  return production
end

def nearest_border_direction(loc)
  max_distance = [map.width, map.height].min / 2

  GameMap::DIRECTIONS.map do |direction|
    distance = 0
    current = loc
    site = map.site(current, direction)

    # maybe find alternative route if we can't move in this direction anyway?
    if site.strength + map.site(loc).strength > 260
      distance += 1
    end

    while(site.owner == tag && distance < max_distance)
      distance += 1
      current = map.find_location(current, direction)
      site = map.site(current)
    end

    {:distance => distance, :direction => direction, :site => site, :location => current}
  end
  .sort_by { |cell| [cell[:distance], -evaluate_production(cell)] }
  .first[:direction]
end

def at_border?(loc)
  GameMap::DIRECTIONS.any? {|d| map.site(loc, d).owner != tag}
end

def main
  init

  while true
    moves = []
    update_game

    (0...map.height).each do |y|
      (0...map.width).each do |x|
        loc = Location.new(x, y)
        site = map.site(loc)

        if site.owner == tag
          move = move(site, loc)
          moves << move unless move.nil?
        end
      end
    end

    network.send_moves(moves)
  end
end

main
