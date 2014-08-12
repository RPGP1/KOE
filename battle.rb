# coding: UTF-8

require 'dxruby'
require_relative './timer'
require_relative './wave'
require_relative './character'
require_relative './bullet'
require_relative './enemy'

class Battle
  def initialize(ai, next_scene, lose_scene)
    Window.fps = 90
    @screen = Sprite.new
    @screen.collision = [0,0,Window.width-1, Window.height-1]
    
    @koe = Wave.new(400,600)
    
    Character.set_wave @koe
    Character.set_base Image.loadTiles("#{game_path}/image/base.png", 2, 1)
    Character.set_background Image.load("#{game_path}/image/back.png")
    
    @characters = [Character.new("#{game_path}/image/girl.png", 2, 1), Character.new("#{game_path}/image/boy.png", 2, 2, type: :down)]
    
    @bullets = []
    @speed = @default_speed = 1.5
    
    @special = {}
    set_special
    
    @ai = ai
    @next_scene = next_scene
  end
  
  private
  
  def enemy_update
    @ai.update(self)
  end
  
  def create_bullet(name, y)
    @bullets << Bullet.create(name, y)
  end
  public :create_bullet
  
  def set_special
    Dir.chdir(File.dirname(__FILE__))
    
    return unless File.directory?('./special_bullet')
    Dir['./special_bullet/*.special'].each do |fname|
      @special[File.basename(fname, '.special').to_sym] = File.read(fname, {encoding: __ENCODING__})
    end
  end
  
  def damage(amount)
    @koe.x = (@koe.x - amount).within(- @koe.width, 0)
    
    if @koe.x == -@koe.width
      lose
    end
  end
  
  def speed_up(amount)
    @speed = (@speed + amount).within(@default_speed, nil)
  end
  
  def special(ary)
    ary.each do |b|
      eval(@special[b]) if @special.has_key?(b)
    end
  end
  
  public
  
  def hp
    @koe.x
  end
  
  def chara_y
    @characters.map{|c| c.y + c.image.height / 2}
  end
  
  def speed
    @speed
  end
  
  def update(left = nil, right = nil)
    @koe.update(left, right)
    
    Character.update(@characters)
    
    ary = Bullet.update(@speed, @characters, @screen, @bullets)
    damage(ary.shift)
    speed_up(ary.shift)
    special(ary)
    
    Bullet.clean(@bullets)
    
    enemy_update
  end
  
  def draw
    @koe.render
    @koe.draw
    
    Character.draw(@characters)
    
    Bullet.draw(@bullets)
    
    nil
  end
  
  def clear
    KOE.change_scene(@next_scene)
  end
  
  def lose
    
  end
end
