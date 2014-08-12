#! coding: UTF-8

require 'dxruby'

class Numeric
  def within(min, max)
    min ||= self
    max ||= self
    if self < min
      return min
    elsif self > max
      return max
    else
      return self
    end
  end
end

module Mouse
  def self.right?
    Input.mouseDown?(M_RBUTTON)
  end
  
  def self.left?
    Input.mouseDown?(M_LBUTTON)
  end
end


class Wave < Sprite
  attr_reader :width, :height, :longer_rate, :longer_speed, :shorter_speed, :hover_frame
  attr_accessor :color, :result_type
  
  class WavePiece
    attr_reader :width, :status
    attr_accessor :height, :max_speed
    
    pi = Math::PI / 180
    ary = Array.new(90) do |i|
      1 - Math.cos(pi * (i + 1))
    end
    @@speedArray = [0] + ary + ary.reverse.map{|v| -v}
    
    def initialize(width, max_speed, hover_count)
      #波
      @default_hover_count = hover_count
      @width = width.within(1, nil)
      @status = :down
      @max_speed = max_speed
      @speed = 0
      @wave = Array.new(@width){0}
      
      #入力
      @input = false
      @time_stamp = nil
    end
    
    def update
      if @status == :fall
        if bottom?
          @status = :down
          update
        end
      else
        if input?
          if top?
            @status = :fall
            @speed = - 90
          else
            unless @status == :up
              @status = :up
              @speed = 0
            end
            @speed = (@speed + 1).within(1, 90)
          end
        else
          if @status == :up
            @status = :hover
            @hover_count = default_hover_count
            update
          elsif @status == :hover
            @speed = 0
            @hover_count -= 1
            if @hover_count < 0
              @status = :down
            end
          else #:down
            @speed = (@speed - 1).within(-90, -1)
          end
        end
      end
      
      @wave.shift
      @wave << (@wave[-1] + speed(@speed).within(- @wave[-1], 1 - @wave[-1])).within(0,1)
    end
    
    def default_hover_count
      @default_hover_count
    end
    
    def top?
      @wave[-1] == 1
    end
    
    def bottom?
      @wave[-1] == 0
    end
    
    def speed(index)
      @@speedArray[index] * @max_speed
    end
    
    def input(*args)
      @input = true
      @time_stamp = Window.running_time
    end
    
    def update_input
      running_time = Window.running_time
      if @time_stamp != running_time
        @input = false
        @time_stamp = running_time
      end
    end
    
    def input?
      update_input
      @input
    end
    
    def to_ary
      @wave.dup
    end
    
    def [](v)
      @wave[v]
    end
    
    def width=(v)
      if @width > v
        @wave = @wave[(@width - v)..-1]
      elsif @width < v
        @wave = [@wave[0]] * (v - @width) + @wave
      end
      @width = v
    end
    
    def hover_frame
      @default_hover_count
    end
    
    def hover_frame=(v)
      @default_hover_count = v
    end
  end
  
  @@stick = Image.new(30,1,[96,255,255,255])
  
  def initialize(width, height, longer_color = [255,165,0], shorter_color = [0,165,255], longer_rate: Rational(3,5), longer_speed: Rational(5, 300), shorter_speed: Rational(9,300), hover_frame: 20)
    super()
    
    @width = width
    @height = height
    @longer_rate = longer_rate
    @longer_height = (h = @height / 2) * @longer_rate
    @shorter_height = h - @longer_height
    @longer_speed = longer_speed
    @shorter_speed = shorter_speed
    @hover_frame = hover_frame
    @pieces = [WavePiece.new(width, @longer_speed, @hover_frame), WavePiece.new(width, @shorter_speed, @hover_frame)]
    
    @color = [longer_color, shorter_color]
    self.image = RenderTarget.new(@width, @height)
    @wave = Array.new(@width){0}
    @wave_longer = Array.new(@width){0}
    @wave_shorter = Array.new(@width){0}
    @wave_image = Image.new(@width, @height).line(0,h-1,@width-1,h-1,@color[0])
                                            .line(0,h,@width-1,h,@color[0])
                                            .line(0,@shorter_height,@width-1,@shorter_height,[128]+@color[0])
                                            .line(0,@height-1-@shorter_height,@width-1,@height-1-@shorter_height,[128]+@color[0])
    @last_draw = [0,0]
    self.z = Layer[:wave]
    
    @result_type = :pixel#, :abso_pixel, :rate
  end
  
  def width=(value)
    return value if @width == value
    
    @pieces.each do |p|
      p.width = value
    end
    self.image.resize(value, @height)
    @wave_longer = @pieces[0].to_ary.map{|v| v * @longer_height}
    @wave_shorter = @pieces[1].to_ary.map{|v| v * @shorter_height}
    @wave = Array.new(value){|i| @wave_longer[i] + @wave_shorter[i]}
    @wave_image.delayed_dispose
    @wave_image = RenderTarget.new(value, @height).drawScale(0,0,@wave_image,value.to_f / @width,1,0,0).to_image
    
    @width = value
  end
  
  def height=(value, force_to_update = false)
    return value if @height == value || force_to_update
    
    @longer_height = (h = value / 2) * @longer_rate
    @shorter_height = h - @longer_height
    
    self.image.resize(@width, value)
    @wave_longer.map{|v| v * value / @height}
    @wave_shorter.map{|v| v * value / @height}
    @wave = Array.new(@width){|i| @wave_longer[i] + @wave_shorter[i]}
    @wave_image.delayed_dispose
    @wave_image = RenderTarget.new(@width, value).drawScale(0,0,@wave_image,1,value.to_f / @height, 0,0).to_image
    @last_draw.map{|v| v * value / @height}
    
    @height = value
  end
  
  def longer_rate=(value)
    @longer_height = (h = @height / 2) * value
    @shorter_height = h - @longer_height
    
    @longer_rate = value
  end
  
  def longer_speed=(value)
    @pieces[0].max_speed = value
    
    @longer_speed = value
  end
  
  def shorter_speed=(value)
    @pieces[1].max_speed = value
    
    @shorter_speed = value
  end
  
  def hover_frame=(value)
    @pieces.each{|p| p.hover_frame = value}
    
    @hover_frame = value
  end
  
  def update(left = nil, right = nil)
    @pieces[0].input if (Mouse.left? && left.nil?) || left
    @pieces[1].input if (Mouse.right? && right.nil?) || right
    
    @pieces.each(&:update)
    
    @wave_longer.shift
    @wave_longer << @pieces[0][-1] * @longer_height
    @wave_shorter.shift
    @wave_shorter << @pieces[1][-1] * @shorter_height
    @wave.shift
    @wave << @wave_longer[-1] + @wave_shorter[-1]
  end
  
  def render
    h = @height / 2
    
    
    #棒
    t = (@width.to_i - 1).div(60)
    tx = @width - 15 - 60 * t
    #t :棒の本数, tx :一本目のx座標
    t.times do |i|
      x_pos = tx + 60 * i
      y_pos = @wave[x_pos + 14]
      rand1 = rand(61) - 30
      rand2 = rand(61) - 30
      self.image.drawScale(x_pos, h - 1 - (mmm = (y_pos + rand1).within(0,nil)), @@stick, 1, mmm + (y_pos + rand2).within(0,nil), 0, 0)
    end
    
    
    #折れ線
    @wave_image.delayed_dispose
    @wave_image = Image.new(@width, @height).draw(-1,0,@wave_image)
    
    old_draw = @last_draw
    new_rand = [rand(21)-10,rand(21)-10]
    @last_draw = [(s = (@wave_shorter[-1]+new_rand[0]).within(0,@shorter_height-1)), s+(@wave_longer[-1]+new_rand[1]).within(0,@longer_height-1)]
    
    @wave_image.line(@width-2,@shorter_height-@wave_shorter[-2],@width-1,@shorter_height-@wave_shorter[-1],[128]+color[0])
               .line(@width-2,@height-1-@shorter_height+@wave_shorter[-2],@width-1,@height-1-@shorter_height+@wave_shorter[-1],[128]+color[0])
               .line(@width-2,h-1-old_draw[0],@width-1,h-1-@last_draw[0],@color[1])
               .line(@width-2,h+old_draw[0],@width-1,h+@last_draw[0],@color[1])
               .line(@width-2,h-1-old_draw[1],@width-1,h-1-@last_draw[1],@color[0])
               .line(@width-2,h+old_draw[1],@width-1,h+@last_draw[1],@color[0])
    
    self.image.drawLine(0,@longer_height,@width-1,@longer_height,[128]+@color[1])
              .drawLine(0,@height-1-@longer_height,@width-1,@height-1-@longer_height,[128]+@color[1])
              .draw(0,0,@wave_image)
  end
  
  def result(type = @result_type)
    case type
    when :pixel
      @wave[-1]
    when :abso_pixel
      @height / 2 - 1 - @wave[-1] + self.y
    when :rate
      @wave[-1].to_f / (@height / 2)
    else
      raise TypeError, "The type has set in wrong way (`#{type}' for :pixel or :abso-pixel or :rate)"
    end
  end
end
