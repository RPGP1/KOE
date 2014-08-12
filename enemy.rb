# coding: UTF-8

require 'fiber'

class EnemyAI
  class Pattern
    def initialize(&block)
      @block = block
      @fiber = nil
    end
    
    def update(battle)
      @fiber ||= Fiber.new(&@block)
      @fiber = Fiber.new(&@block) unless @fiber.alive?
      @fiber.resume(battle)
    end
  end
  
  @@patterns = {}
  
  def self.create_pattern(name, &block)
    @@patterns[name] = Pattern.new(&block)
  end
  
  def initialize(fiber = nil, &block)
    @fiber = fiber if Fiber === fiber
    @fiber = Fiber.new(&block)
    
    @now_pattern = @@patterns[@fiber.resume]
  end
  
  def update(battle)
    result = @now_pattern.update(battle)
    
    if result == :next
      @now_pattern = @@patterns[@fiber.resume]
    end
  end
end

EnemyAI.create_pattern(:easy) do |battle|
  10.times do
    battle.create_bullet(:normal, rand(600))
    90.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:speed) do |battle|
  15.times do
    battle.create_bullet(:speed, rand(600))
    60.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:easy_double) do |battle|
  7.times do
    battle.create_bullet(:normal, rand(600))
    rand
    rand
    battle.create_bullet(:normal, rand(600))
    90.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:speed_double) do |battle|
  9.times do
    battle.create_bullet(:speed, rand(600))
    rand
    rand
    battle.create_bullet(:speed, rand(600))
    120.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:easy_chase) do |battle|
  10.times do
    battle.create_bullet(:normal, battle.chara_y[rand(2)])
    150.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:speed_chase) do |battle|
  15.times do
    battle.create_bullet(:speed, battle.chara_y[rand(2)])
    150.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:three) do |battle|
  5.times do
    y = battle.chara_y[rand(2)]
    battle.create_bullet(:normal, y - 50)
    battle.create_bullet(:normal, y + 50)
    90.div(battle.speed).times{Fiber.yield}
    battle.create_bullet(:speed, y)
    200.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:five) do |battle|
  5.times do
    y = battle.chara_y[rand(2)]
    battle.create_bullet(:normal, y - 70)
    battle.create_bullet(:normal, y - 50)
    battle.create_bullet(:normal, y + 50)
    battle.create_bullet(:normal, y + 70)
    90.div(battle.speed).times{Fiber.yield}
    battle.create_bullet(:speed, y)
    200.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:wall_easy) do |battle|
  dy = 100 * rand(2) + 50
  y1 = 300 - dy
  y2 = 300 + dy
  
  battle.create_bullet(:wall, y1 - 50)
  battle.create_bullet(:wall, y1 + 50)
  battle.create_bullet(:wall, y2 - 50)
  battle.create_bullet(:wall, y2 + 50)
  
  ((y1 - 50 - 10).div(210) + 1).times do |i|
    battle.create_bullet(:strong, y1-50-10-100-210*i)
    battle.create_bullet(:strong, y2+50+10+100+210*i)
  end
  
  (y2-y1-20).div(200).times do |i|
    battle.create_bullet(:strong, y1 + 150+200*i)
  end
  
  350.times{Fiber.yield}
  Fiber.yield :next
end

EnemyAI.create_pattern(:wall_hard) do |battle|
  dy = 100 * rand(3) + 50
  y1 = 300 - dy
  y2 = 300 + dy
  
  battle.create_bullet(:wall, y1 - 50)
  battle.create_bullet(:wall, y1 + 50)
  battle.create_bullet(:wall, y2 - 50)
  battle.create_bullet(:wall, y2 + 50)
  
  ((y1 - 50 - 10).div(210) + 1).times do |i|
    battle.create_bullet(:strong, y1-50-10-100-210*i)
    battle.create_bullet(:strong, y2+50+10+100+210*i)
  end
  
  (y2-y1-20).div(200).times do |i|
    battle.create_bullet(:strong, y1 + 150+200*i)
  end
  
  350.times{Fiber.yield}
  Fiber.yield :next
end

EnemyAI.create_pattern(:tricky) do |battle|
  7.times do
    battle.create_bullet(:cure_little, rand(300))
    battle.create_bullet(:strong, rand(300) + 300)
    250.times{Fiber.yield}
  end
  8.times do
    battle.create_bullet(:strong, rand(300))
    battle.create_bullet(:cure_little, rand(300) + 300)
    250.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:cure) do |battle|
  battle.create_bullet(:cure, rand(600))
  300.times{Fiber.yield}
  Fiber.yield :next
end

EnemyAI.create_pattern(:cure_strong) do |battle|
  battle.create_bullet(:cure_strong, rand(600))
  225.times{Fiber.yield}
  Fiber.yield :next
end

EnemyAI.create_pattern(:cure_little) do |battle|
  4.times do
    battle.create_bullet(:cure_little, rand(600))
    90.times{Fiber.yield}
  end
  Fiber.yield :next
end

EnemyAI.create_pattern(:finish) do |battle|
  ary = [:normal] * 25 + [:speed] * 40 + [:wall] * 20 + [:strong] * 10 + [:cure_little] * 7
  
  loop do
    battle.create_bullet(:clear, 300)
    
    (
      (520.0 / (battle.speed * 0.08)) / 75
    ).to_i.times do
      battle.create_bullet(ary.sample, ([rand(600)] * 2 + [battle.chara_y[rand(2)]]).sample)
      
      80.times{Fiber.yield}
    end
  end
  Fiber.yield :next
end
