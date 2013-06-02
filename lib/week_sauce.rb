class WeekSauce
  MAX_VALUE = 2**7 - 1
  
  def initialize(value = nil)
    @value = [[0, value.to_i].max, MAX_VALUE].min
  end
  
  def blank?
    @value == 0
  end
  
  def all?
    @value == MAX_VALUE
  end
  
  def any?
    !blank?
  end
  
  def single?
    any? && @value & (@value - 1) == 0
  end
  
  def many?
    any? && !single?
  end
  
  def to_i
    @value
  end
end
