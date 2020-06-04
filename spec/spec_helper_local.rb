class TF
  def self.dispatch(*); end
end

module Puppet::Functions
  def self.create_function(_name, &block)
    TF.class_eval(&block)
  end
end
