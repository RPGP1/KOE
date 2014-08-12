# coding: UTF-8

def game_path
  File.dirname(caller[0][/^.\:[^\:]*(?=\:)/])
end

require 'dxruby'
require_relative './battle'
require_relative './transition'

Window.resize(800,600)
AfterClear = Image.load(game_path + '/image/after_clear.png')
Loading = Image.loadTiles(game_path + '/image/Loading.png', 1, 10)
Rule = Image.load(game_path + '/image/rule.png')

module KOE
  def self.change_scene(scene)
    scene.old_scene = @@scene if scene.respond_to?(:old_scene=)
    @@scene = scene
  end
  
  def self.update
    @@scene.update if @@scene.respond_to?(:update)
  end
  
  def self.draw
    @@scene.draw if @@scene.respond_to?(:draw)
  end
end

ai = EnemyAI.new do
  Fiber.yield :easy
  Fiber.yield :cure_little
  Fiber.yield :speed
  Fiber.yield :easy_double
  Fiber.yield :speed
  Fiber.yield :speed_chase
  Fiber.yield :cure
  Fiber.yield :easy_chase
  Fiber.yield :speed_chase
  Fiber.yield :speed_double
  Fiber.yield :cure_strong
  Fiber.yield :three
  Fiber.yield :five
  Fiber.yield :wall_easy
  Fiber.yield :wall_easy
  Fiber.yield :wall_hard
  Fiber.yield :wall_hard
  Fiber.yield :tricky
  Fiber.yield :finish
end

KOE.change_scene(Battle.new(ai, nil, nil))

Window.loop do
  KOE.update
  KOE.draw
  
  Window.caption = Window.real_fps.to_s
end
