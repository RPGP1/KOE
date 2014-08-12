# coding: UTF-8

require 'dxruby'
require_relative './animation'

class Bullet < AnimeSprite
  class BulletPrototype
    attr_accessor :speed_rate, :speed_adjust, :damage, :speed_penalty, :special, :collision
    attr_reader :block
    
    @@list = {}
    
    def self.create(name, y)
      @@list[name].create(y)
    end
    
    def initialize(name, image, x_count = 1, y_count = 1, speed_rate: 1, speed_adjust: 0, damage: 7, speed_penalty: 0, special: nil, collision: nil, &block)
      @x_count = x_count
      @y_count = y_count
      
      @img = (Image === image ? image : Image.load(image))
      @img = @img.sliceTiles(@x_count, @y_count)
      
      @speed_rate = speed_rate
      @speed_adjust = speed_adjust
      @damage = damage
      @speed_penalty = speed_penalty
      @special = special
      @collision = nil
      
      @block = block
      
      @@list[name] = self
    end
    
    def w_block(&block)
      @block = block
    end
    
    def create(y)
      bullet = Bullet.new(y, @img)
      
      bullet.speed_rate = @speed_rate
      bullet.speed_adjust = @speed_adjust
      bullet.damage = @damage
      bullet.speed_penalty = @speed_penalty
      bullet.special = @special
      bullet.collision = @collision
      bullet.block = @block
      
      bullet
    end
  end
  
  def self.create(name, y)
    BulletPrototype.create(name, y)
  end
  
  def self.update(speed, characters, screen, *args)
    sum = [0,0]
    args.each do |obj|
      if Array === obj
        unless obj.empty?
          return self.update(speed, characters, screen, *obj)
        else
          return 0,0,nil
        end
      else
        if obj.respond_to?(:update)
          ary = obj.update(speed, characters, screen)
          sum[0] += ary[0]
          sum[1] += ary[1]
          sum << ary[2] if ary[2]
        end
      end
    end
    
    sum
  end
  
  attr_accessor :speed_rate, :speed_adjust, :damage, :speed_penalty, :special, :block
  
  def initialize(y, image_array)
    super()
    
    self.animation_image = image_array
    add_animation(:usual, 60.div(image_array.size), Array.new(image_array.size){|i| i})
    start_animation(:usual)
    
    self.x = Window.width
    self.y = y - self.image.height / 2
    
    @speed_rate = 1
    @speed_adjust = 0
    @damage = 0
    @speed_penalty = 0
    @special = nil
    @block = nil
  end
  
  def update(speed, characters, screen)
    update_animation
    
    self.x -= (speed + @speed_adjust) * @speed_rate
    
    @block.call(self) if @block
    
    if self === characters #Bullet.check(self, characters, nil, nil)
      self.vanish
      return @damage, @speed_penalty, @special
    else
      return 0, 0, nil
    end
    
    unless self === screen #Bullet.check(self, screen, nil, nil)
      self.vanish
      return 0,0,nil
    end
  end
end
str = game_path
Bullet::BulletPrototype.new(:normal, str + '/image/bullet1.png')
Bullet::BulletPrototype.new(:speed, str + '/image/bullet2.png', speed_rate: 1.5, damage: 7, speed_penalty: 0.1)
Bullet::BulletPrototype.new(:wall, str + '/image/bullet3.png', speed_rate: 0.8, damage: 8, speed_penalty: 0.05, collision: [[0,9,10,0,10,19],[189,0,189,19,199,9],[11,5,188,13]])
Bullet::BulletPrototype.new(:strong, str + '/image/bullet4.png', 6, 1, speed_rate: 0.8, damage: 9, collision: [100,100,100])

Bullet::BulletPrototype.new(:cure, str + '/image/bullet_cure.png', speed_rate: 3, damage: -20, speed_penalty: -1)
Bullet::BulletPrototype.new(:cure_strong, str + '/image/bullet_cure2.png', speed_rate: 4, damage: -70, speed_penalty: -2)
Bullet::BulletPrototype.new(:cure_little, str + '/image/bullet_cure2.png', speed_rate: 2, damage: -5, speed_penalty: -0.1)

Bullet::BulletPrototype.new(:clear, str + '/image/bullet_clear.png', speed_rate: 0.08 ,damage: -9999, speed_penalty: -9999, special: :clear)
