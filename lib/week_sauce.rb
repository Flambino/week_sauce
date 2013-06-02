require 'date'

# WeekSauce is a simple class that functions as a days-of-the-week bitmask.
# Useful for things that repeat weekly, and/or can occur or one or more days
# of the week.
# 
# Extracted from a Rails app, it's intended to be used an ActiveRecord
# attribute serializer, but it should work fine outside of Rails.
# 
# Basic usage
# 
#   week = WeekSauce.new
#   week.blank?          #=> true
#   
#   # Mark off the weekend
#   week.saturday = true
#   week.sunday = true
#   
#   week.any?            #=> true
#   
# Days can be set and read using Fixnums, symbols or Date/Time objects.
# Additionally, there are named methods for getting and setting each of
# the week's days:
#
#   week.friday = true
#   week.friday          #=> true
#   week.friday?         #=> true
# 
# *Note:* Similar to <tt>Time#wday</tt>, day-numbers start with Sunday as zero,
# Monday => 1, Tuesday => 2, etc.
#   
#   week[0] = true       # sets Sunday
#   week[0]              # => true
#
#   week[:sunday] = true
#   week[:sunday]        # => true
#   
#   time = Time.now
#   week[time] = true    # same as week[time.wday] = true
#   week[time]           # => true
class WeekSauce
  MAX_VALUE = 2**7 - 1
  DAY_NAMES = %w(sunday monday tuesday wednesday thursday friday saturday).map(&:to_sym).freeze
  DAY_BITS  = Hash[ DAY_NAMES.zip(Array.new(7) { |i| 2**i }) ].freeze
  
  # Init a new WeekSauce instance. If +value+ is omitted, the new
  # instance will default to a bitmask of zero, i.e. no days set.
  # 
  # If a +value+ argument is given, +to_i+ will be called on it,
  # and the resulting integer will be clamped to 0..127
  def initialize(value = nil)
    @value = [[0, value.to_i].max, MAX_VALUE].min
  end
  
  # Compare this instance against another instance, or a Fixnum
  def ==(arg)
    case arg
    when self.class, Fixnum
      to_i == arg.to_i
    else
      false
    end
  end
  
  # Returns +true+ if no days are set, +false+ otherwise.
  # Opposite of #any?
  def blank?
    @value == 0
  end
  
  # Returns +true+ if all days are set, +false+ otherwise
  def all?
    @value == MAX_VALUE
  end
  
  # Returns +true+ if any of the week's 7 days are set, +false+ otherwise.
  # Opposite of #blank?
  def any?
    !blank?
  end
  
  # Returns +true+ if exactly one day is set, +false+ otherwise
  def one?
    any? && @value & (@value - 1) == 0
  end
  
  # Returns +true+ if two or days are set, +false+ otherwise
  def many?
    any? && !one?
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
  
  # Returns +true+ if the given weekday is set, +false+ if it isn't,
  # and +nil+ if the argument was invalid.
  # 
  # The +wday+ argument can be a Fixnum from 0 (Sunday) to 6 (Saturday),
  # a symbol specifying the day's name (e.g. +:tuesday+, +:friday+), or
  # a Date or Time instance
  def [](wday)
    get coerce_to_bit(wday)
  end
  
  # Set or unset the given day. See #[] for possible +wday+ values.
  # Invalid +wday+ values are ignored.
  def []=(wday, bool)
    set coerce_to_bit(wday), bool
  end
  
  # Set all days to +false+
  def blank!
    @value = 0
    self
  end
  
  # Set all days to +true+
  def all!
    @value = MAX_VALUE
    self
  end
  
  # Returns the raw bitmask integer
  def to_i
    @value
  end
  
  def to_a
    DAY_NAMES.select { |day| self[day] }
  end
  
  def to_hash
    Hash[ DAY_NAMES.map { |day| [day, self[day]] } ]
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
