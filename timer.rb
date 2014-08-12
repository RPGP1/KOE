# coding: UTF-8

require 'dxruby'
require_relative './push_keys'
#require_relative './screen'

=begin
class Timer

# Abstract ###################
  タイマー機能のクラスです。Window.before_call/after_callを内部で使用しています。

# Timerの状態 ################
  個々のTimerは、以下の実行状態を持ちます。これらの状態はObject#inspectやTimer#statusによって見ることができます。
  
  run(実行状態)
    生成されたばかりのTimerやTimer#runで起こされたTimerはこの状態です。この状態のTimerは「生きて」います。
  
  stop(停止状態)
    Timer#stopにより停止されたTimerはこの状態になります。この状態のTimerは「生きて」います。
  
  dead(終了状態)
    Timer#killで終了したTimerはこの状態になります。この状態のスレッドは「死んで」います。Timerクラス内で参照されなくなるので、ユーザが参照していない場合はGCに回収されるようになります。

# Singleton Methods ##########
  new(method, count: 1, limit: nil, periority: 0, timing: :after, keys: :push_keys) -> Timer
    指定した情報でTimerオブジェクトを生成します。生成されたTimerはそのフレームから動き出します。
    
    [PARAM] method:
      Timerの呼び出すオブジェクト。MethodやProcなど`call'メソッドを持つオブジェクトを渡します。
      引数を取るオブジェクトを登録すると呼び出す時に、前に呼び出されてからの間に押されたキーと、最後に何フレーム目に押されたかを関連付けたハッシュを渡します。
    
    [PARAM] count:
      methodをTimerが呼び出す間隔。フレーム数を表す整数で指定します。
      何も指定しないと1、すなわち毎フレーム呼び出されます。
    
    [PARAM] limit:
      methodをTimerが呼び出す回数。整数またはnil(制限なし)で指定します。
      何も指定しないとnilです。
    
    [PARAM] periority:
      Timerを更新する際の優先度。数を指定します。
      これが同じ場合の動作は複雑なので、順番が重要なTimerには必ず適した優先度を設定してください。
    
    [PARAM] timing:
      Timerを更新するタイミングを指定します。:beforeと:afterで指定します。
    
    [PARAM] keys:
      methodに渡すkey情報の取得を、Input.keysかInput.push_keysかから選んで指定します。
      :keysか:push_keysで指定します。
  
  list -> [Timer]
    「生きて」いるTimerの優先度順の配列を返します。

# Instance Methods ###########
  kill -> self
    Timerの実行を終了させます。
  
  run -> self
    Timerがstopしていた場合再開させます。この時、フレーム数のカウントは一度初めに戻ります。
  
  stop -> self
    Timerが「生きて」いた場合停止させます。
  
  status -> String | false
    Timerが「生きて」いる場合は対応する文字列("run" または "stop")を、「死んで」いる場合はfalseを返します。
  
  alive? -> bool
    Timerが「生きて」いるかを返します。
  
  stop? -> bool
    Timerが停止または終了しているかを返します。
  
  parent -> Object
    Timerが`call'メソッドを呼び出すオブジェクトを返します。
  
  value -> Integer | nil
    Timerが呼び出す残り回数を返します。ただし無限Timerの場合はnilを返します。
  
  timing -> :before | :after
    Timerが呼び出されるのがフレームの前か後かを示します。
  
  periority -> Numeric
  periority=(value) -> Numeric
    Timerの優先度を数で取得・設定します。
=end

class Timer
  @@list = []
  
  def initialize(method, count: 1, limit: nil, periority: 0, timing: :after, keys: :push_keys)
    @parent = method #Timerが呼び出すMethod
    @send_key = (method.arity != 0) #methodを呼び出すときにキャッシュしたキーを渡すか
    @default_count = @count = count #Timerが呼び出す間隔
    @value = limit #Timerを呼び出す回数 0以下になると自動でkill
    @periority = periority
    @timing = timing
    @key_gets = keys
    
    @status = "run"
    @keys = {} #cacheしたキー情報格納
    
    @@list << self
    
    self
  end
  
  def self.list
    @@list.clone
  end
  
  def self.before_list
    @@list.clone.select{|t| t.timing == :before}
  end
  
  def self.after_list
    @@list.clone.select{|t| t.timing == :after}
  end
  
  def self.after_update
    @@list.sort_by!{|x| -(x.periority)} #優先度順に並び替え
    Sprite.update(after_list) #それぞれ#updateする
  end
  
  def self.before_update
    @@list.sort_by!{|x| -(x.periority)} #優先度順に並び替え
    Sprite.update(before_list) #それぞれ#updateする
  end
  private_class_method :after_update, :before_update
  
  attr_reader :parent, :value, :timing
  attr_accessor :periority
  
  def kill
    @status = "dead"
    @@list.delete(self)
    
    @value = 0
    
    self
  end
  
  def run
    if @status == "stop"
      @status = "run" #statusをrunにして、
      @count = @default_count #countを最初の数に
      @keys.clear #cacheも初期化
    end
    self
  end
  
  def stop
    if self.alive?
      @status = "stop"
    end
    self
  end
  
  def status
    result = @status
    result = false if @status == "dead"
    result
  end
  
  def alive?
    @status == "run" || @status == "stop"
  end
  
  def stop?
    @status == "dead" || @status == "stop"
  end
  
  def inspect
    "#<Timer:#{self.object_id} #{@status} method:#{@parent.inspect}>"
  end
  
  def update
    #このコードの要。毎フレームのTimerの更新
    
    #まず.new時にlimitに0以下の値が指定されていた時の対策
    if @value
      self.kill if @value <= 0
    end
    
    if @status == "run"
      #更新するのはstatusがrunの時
      
      Input.__send__(@key_gets).each do |k|
        @keys[k] = @default_count - @count + 1
      end
      
      @count -= 1
      if @count <= 0
        #カウントしきった時
        
        #登録したものを呼び出す
        if @send_key
          @parent.call(@keys)
        else
          @parent.call
        end
        
        @count = @default_count #最初のに戻す
        @keys.clear
        
        if @value #有限Timerの時
          @value -= 1
          self.kill if @value <= 0#指定分呼び出したらGood bye!
        end
      end
    end
    
    self
  end
  
  Window.after_call[:timer_class_update] = Timer.method(:after_update)
  Window.before_call[:timer_class_update] = Timer.method(:before_update)
end


#Timerから渡されたハッシュを基に、配列の要素から押されてないキーを除き、残ったキーを押された逆順に並び替える。
class Array
  def sort_keys(keys)
    self.select{|k|
      keys.key?(k)
    }.sort_by{|k|
      -(keys[k])
    }
  end
  
  def sort_keys!(keys)
    self.replace(select{|k|
      keys.key?(k)
    }.sort_by{|k|
      -(keys[k])
    })
  end
end
