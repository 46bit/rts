# A quadtree with some special properties useful for this game:
#
# - Collisions between units belonging to the same player are
#   completely ignored. This isn't just about the searching. This
#   tweaked quadtree datastructure doesn't break quadrants down any
#   further once units belonging to only a single player are present.
#   This realised a 20%-ish performance improvement for 4 players each
#   with 50 units.
Quadtree = Struct.new(:bounds, :units, :subtrees, :player)

class Quadtree
  def self.from_units(units)
    bounds = bounds_from_units(units)
    self.quadrant(bounds, units)
  end

  def self.from_turret_ranges(turrets)
    bounds = bounds_from_unit_ranges(turrets)
    self.quadrant(bounds, turrets, contains_check: lambda { |a, b| bounds_contains_turret_ranges(a, b) } )
  end

  def self.quadrant(bounds, units, contains_check: lambda { |a, b| bounds_contains_unit(a, b) })
    if units.length <= 1 || (units.map(&:player).uniq.length == 1)
      return Quadtree.new(bounds, units, [], units[0]&.player)
    end

    parent_units = []
    quadrants_units = [[], [], [], []]
    quadrants_bounds = quadrant_bounds(bounds)
    units.each do |unit|
      assigned = false
      quadrants_bounds.each_with_index do |quadrant_bounds, i|
        if contains_check.call(quadrant_bounds, unit)
          quadrants_units[i] << unit
          assigned = true
          break
        end
      end
      parent_units << unit unless assigned
    end

    quadtrees = []
    if parent_units.length < units.length
      quadtrees = (0...4).map do |i|
        Quadtree.quadrant(quadrants_bounds[i], quadrants_units[i], contains_check: contains_check)
      end
    end

    Quadtree.new(bounds, parent_units, quadtrees, nil)
  end

  def units_inc_subtrees
    units + subtrees.map(&:units_inc_subtrees).flatten
  end

  def collisions(with_units)
    collisions = {}
    with_units.each do |unit1|
      collisions[unit1] = []
      units.each do |unit2|
        next if unit1 == unit2
        next if !unit1.respond_to?(:player) || (unit1.player && unit1.player == unit2.player)

        if unit1.collided?(unit2)
          collisions[unit1] << unit2
        end
      end
      subtrees.each do |subtree|
        next unless bounds_contains_unit(subtree.bounds, unit1) && (unit1.player.nil? || subtree.player != unit1.player)

        collisions[unit1] += subtree.collision_for(unit1)
      end
      #collisions[unit1].sort_by!(&:object_id)
    end

    collisions.each do |k, v|
      collisions.delete(k) if v.empty?
    end

    collisions
  end

  def collision_for(unit1, player: unit1.player, within: 0)
    unit_collisions = []
    units.each do |unit2|
      next if unit1 == unit2

      if unit1.collided?(unit2, within: within)
        next if !player.nil? && player == unit2.player

        unit_collisions << unit2
      end
    end
    subtrees.each do |subtree|
      next unless bounds_contains_unit(subtree.bounds, unit1) && (player.nil? || subtree.player != player)

      unit_collisions += subtree.collision_for(unit1, player: player, within: within)
    end
    unit_collisions
  end
end

def bounds_from_units(units)
  {
    left: units.map { |u| u.position[0] - u.collision_radius }.min,
    right: units.map { |u| u.position[0] + u.collision_radius }.max,
    top: units.map { |u| u.position[1] - u.collision_radius }.min,
    bottom: units.map { |u| u.position[1] + u.collision_radius }.max,
  }
end

def bounds_from_unit_ranges(units)
  {
    left: units.map { |u| u.position[0] - TurretProjectile::RANGE }.min,
    right: units.map { |u| u.position[0] + TurretProjectile::RANGE }.max,
    top: units.map { |u| u.position[1] - TurretProjectile::RANGE }.min,
    bottom: units.map { |u| u.position[1] + TurretProjectile::RANGE }.max,
  }
end

def quadrant_bounds(parent_bounds)
  width = parent_bounds[:right] - parent_bounds[:left]
  height = parent_bounds[:bottom] - parent_bounds[:top]
  centre_x = parent_bounds[:left] + width / 2.0
  centre_y = parent_bounds[:top] + height / 2.0

  top_left = {
    left: parent_bounds[:left],
    right: centre_x,
    top: parent_bounds[:top],
    bottom: centre_y,
  }
  top_right = {
    left: centre_x,
    right: parent_bounds[:right],
    top: parent_bounds[:top],
    bottom: centre_y,
  }
  bottom_left = {
    left: parent_bounds[:left],
    right: centre_x,
    top: centre_y,
    bottom: parent_bounds[:bottom],
  }
  bottom_right = {
    left: centre_x,
    right: parent_bounds[:right],
    top: centre_y,
    bottom: parent_bounds[:bottom],
  }
  [top_left, top_right, bottom_left, bottom_right]
end

def bounds_contains_unit(bounds, unit)
  unit_left = unit.position[0] - unit.collision_radius
  unit_right = unit.position[0] + unit.collision_radius
  unit_top = unit.position[1] - unit.collision_radius
  unit_bottom = unit.position[1] + unit.collision_radius
  unit_left >= bounds[:left] && unit_right <= bounds[:right] && unit_top >= bounds[:top] && unit_bottom <= bounds[:bottom]
end

def bounds_contains_turret_ranges(bounds, turret)
  unit_left = unit.position[0] - TurretProjectile::RANGE
  unit_right = unit.position[0] + TurretProjectile::RANGE
  unit_top = unit.position[1] - TurretProjectile::RANGE
  unit_bottom = unit.position[1] + TurretProjectile::RANGE
  unit_left >= bounds[:left] && unit_right <= bounds[:right] && unit_top >= bounds[:top] && unit_bottom <= bounds[:bottom]
end

def draw_quadtree(quadtree, renderer)
  puts "bounds='#{quadtree.bounds.inspect}' unit_count=#{quadtree.units.length}"
  top_line = renderer.line(
    x1: quadtree.bounds[:left],
    y1: quadtree.bounds[:top],
    x2: quadtree.bounds[:right],
    y2: quadtree.bounds[:top],
    width: 1,
    color: "red",
    z: 9999,
  )
  bottom_line = renderer.line(
    x1: quadtree.bounds[:left],
    y1: quadtree.bounds[:bottom],
    x2: quadtree.bounds[:right],
    y2: quadtree.bounds[:bottom],
    width: 1,
    color: "red",
    z: 9999,
  )
  left_line = renderer.line(
    x1: quadtree.bounds[:left],
    y1: quadtree.bounds[:top],
    x2: quadtree.bounds[:left],
    y2: quadtree.bounds[:bottom],
    width: 1,
    color: "red",
    z: 9999,
  )
  right_line = renderer.line(
    x1: quadtree.bounds[:right],
    y1: quadtree.bounds[:top],
    x2: quadtree.bounds[:right],
    y2: quadtree.bounds[:bottom],
    width: 1,
    color: "red",
    z: 9999,
  )
  lines = [top_line, bottom_line, left_line, right_line]
  #sleep 3
  #top_line.remove
  #bottom_line.remove
  #left_line.remove
  #right_line.remove
  (quadtree.subtrees || []).each do |subtree|
    lines += draw_quadtree(subtree, renderer)
  end
  lines
  # sleep 3
  # top_line.remove
  # bottom_line.remove
  # left_line.remove
  # right_line.remove
end
