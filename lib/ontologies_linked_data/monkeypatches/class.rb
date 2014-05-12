class Class
  ##
  # List all descendant classes of class
  def descendants # :nodoc:
    descendants = []
    ObjectSpace.each_object(singleton_class) do |k|
      descendants.unshift k unless k == self
    end
    descendants
  end
end