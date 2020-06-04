class TF
  def self.dispatch(name, &block)
  end
end


module Puppet
  module Functions
    def self.create_function(name, &block)
      TF.class_eval(&block)
    end
  end
end
