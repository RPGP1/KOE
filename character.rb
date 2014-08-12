# coding: UTF-8

require 'dxruby'
require_relative './layer'
require_relative './wave'
require_relative './animation'


class Character < AnimeSprite
  def self.set_wave(wave)
    @@wave = wave
    
    nil
  end
  
  def self.set_base(image_ary)
    @@base = image_ary.dup
  end
  
  def self.set_background(image)
    @@background = image
  end
  
  def self.wave
    @@wave
  end
  
  def self.base
    @@base
  end
  
  def self.background
    @@background
  end
  
  def self.draw(*args)
    args.each do |obj|
      if Array === obj
        self.draw(*obj) unless obj.empty?
      else
        obj.draw_base if obj.respond_to?(:draw_base)
        obj.draw_body if obj.respond_to?(:draw_body)
        obj.draw_back if obj.respond_to?(:draw_back)
      end
    end
    
    nil
  end
  
  class CharacterBase < AnimeSprite
    def initialize(type = :high)
      case type
      when :up
        @type = type
        @scale = -1
        self.z = Layer[:character_base_up]
      when :down
        @type = type
        @scale = 1
        self.z = Layer[:character_base_down]
        self.angle = 180
      else
        raise TypeError, "the type has set wrong (`#{type}' for :up or :down)"
      end
      
      super()
      
      ary = self.animation_image = Character.base
      add_animation(:usual, 60.div(ary.size), Array.new(ary.size){|i| i})
      start_animation(:usual)
    end
    
    def update(dx = 0, dy = 0)
      self.x = (w = Character.wave).x + w.width - self.image.width / 2 + dx
      self.y = w.y + w.height / 2 + w.result(:pixel) * @scale - self.image.height / 2 + dy
      
      update_animation
      
      nil
    end
  end
  
  class CharacterBackground < Sprite
    def initialize(type)
      super
      self.image = Character.background
      
      case type
      when :up
        @type = type
        @scale = -1
        self.z = Layer[:character_back_up]
      when :down
        @type = type
        @scale = 1
        self.z = Layer[:character_back_down]
      else
        raise TypeError, "the type has set wrong (`#{type}' for :up or :down)"
      end
    end
    
    def update(dx = 0, dy = 0)
      self.x = (w = Character.wave).x + w.width - self.image.width / 2 + dx
      self.y = w.y + w.height / 2 + w.result(:pixel) * @scale - self.image.width / 2 + dy
    end
  end
  
  def initialize(image, x_count = 1, y_count = 1, dx: 0, dy: 0, type: :up)
    super()
    @x_count = x_count
    @y_count = y_count
    
    @img = (Image === image ? image : Image.load(image))
    @img = @img.sliceTiles(@x_count, @y_count)
    
    @dx = dx
    @dy = dy
    case type
    when :up
      @type = type
      @scale = -1
      self.z = Layer[:character_body_up]
    when :down
      @type = type
      @scale = 1
      self.z = Layer[:character_body_down]
    else
      raise TypeError, "the type has set wrong (`#{type}' for :up or :down)"
    end
    
    @background = CharacterBackground.new(type)
    @base = CharacterBase.new(type)
    
    self.animation_image = @img
    add_animation(:usual, 60.div(@x_count * @y_count), Array.new(@x_count * @y_count){|i| i})
    start_animation(:usual)
    
    self.collision = [w = self.image.width / 2, h = self.image.height / 2, (w + h) / 2]
  end
  
  def update
    self.x = (w = Character.wave).x + w.width - self.image.width / 2 + @dx
    self.y = w.y + w.height / 2 + w.result(:pixel) * @scale - self.image.width / 2 + @dy
    
    @base.update(0, (- self.image.height / 2) * @scale)
    @background.update(@dx,@dy)
    
    self.update_animation
    
    nil
  end
  
  def draw_body
    draw
  end
  
  def draw_base
    @base.draw
  end
  
  def draw_back
    @background.draw
  end
end
