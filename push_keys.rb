# coding: UTF-8

require "dxruby"

module DXRuby
  KeyNames = self.constants.keep_if{|c| c[0..1] == "K_"}.freeze
  KeyCodes = KeyNames.dup.map{|k| self.const_get(k)}.freeze
  Keys = Hash.new.tap{|h| KeyNames.each_with_index{|n, i| h[n] = KeyCodes[i]}}.freeze
end

module Input
  def self.push_keys
    KeyCodes.dup.keep_if{|k| keyPush?(k)}
  end
  
  def self.push_x(keys = self.push_keys)
    (keys.include?(K_RIGHT) ? 1 : 0) - (keys.include?(K_LEFT) ? 1 : 0)
  end
  
  def self.push_y(keys = self.push_keys)
    (keys.include?(K_DOWN) ? 1 : 0) - (keys.include?(K_UP) ? 1 : 0)
  end
end
