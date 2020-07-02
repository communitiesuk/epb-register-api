require "sinatra/activerecord"

class Container
  def initialize
    @objects = {
    }
  end

  def get_object(key)
    @objects[key]
  end
end
