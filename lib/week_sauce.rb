require 'date'

class WeekSauce
  MAX_VALUE = 2**7 - 1
  DAY_NAMES = %w(sunday monday tuesday wednesday thursday friday saturday).map(&:to_sym).freeze
  DAY_BITS  = Hash[ DAY_NAMES.zip(Array.new(7) { |i| 2**i }) ].freeze
  
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
  
  DAY_BITS.each do |day, bit|
    define_method("#{day.to_s}?") do
      get bit
    end
    
    define_method("#{day.to_s}") do
      get bit
    end
    
    define_method("#{day.to_s}=") do |bool|
      set bit, bool
    end
  end
  
  def [](wday)
    get coerce_to_bit(wday)
  end
  
  def []=(wday, bool)
    set coerce_to_bit(wday), bool
  end
  
  def to_i
    @value
  end
  
  private
  
    def get(bit)
      if DAY_BITS.values.include?(bit)
        @value & bit > 0
      end
    end
    
    def set(bit, set)
      if DAY_BITS.values.include?(bit)
        if set
          @value = @value | bit
        else
          @value = @value & (MAX_VALUE ^ bit)
        end
      end
    end
    
    def coerce_to_bit(wday)
      case wday
      when Symbol
        DAY_BITS[wday]
      when Fixnum
        (0..6).include?(wday) ? 2**wday : nil
      when Date, Time
        2**wday.wday
      end
    end
  
end
