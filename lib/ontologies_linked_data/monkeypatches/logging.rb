require 'logger'

class Logger
  def flush
    ((self.instance_variable_get :@logdev).instance_variable_get :@dev).flush
  end
end
