require 'date'
# 
# {<img src="https://travis-ci.org/Flambino/week_sauce.png?branch=master" alt="Build Status" />}[https://travis-ci.org/Flambino/week_sauce]
# {<img src="https://badge.fury.io/rb/week_sauce.png" alt="Gem Version" />}[http://badge.fury.io/rb/week_sauce]
# {<img src="https://codeclimate.com/github/Flambino/week_sauce.png" />}[https://codeclimate.com/github/Flambino/week_sauce]
# 
# WeekSauce is a simple class that functions as a days-of-the-week bitmask. Useful for things that repeat weekly, and/or can occur on one or more days of the week.
# 
# It was extracted from a Rails app, and is primarily intended to used as an ActiveRecord attribute serializer, but it should work fine outside of Rails too.
# 
# == The Basics
# 
#   week = WeekSauce.new(16) # init with bitmask (optional)
#   week.blank?     #=> false
#   week.one?       #=> true
#   week.thursday?  #=> true
#   
#   week = WeekSauce.new     # defaults to a zero-bitmask
#   week.blank? #=> true
#   
#   # Mark the weekend
#   week.set(:saturday, :sunday)
#   
#   from = Time.parse("2013-04-01") # A Monday
#   week.next_date(from)            #=> Sat, 06 Apr 2013
#   
#   week.dates_in(from..from + 1.week) => [Sat, 06 Apr 2013 , Sun, 07 Apr 2013]
# 
# == Usage with ActiveRecord
# 
#   class Workout < ActiveRecord::Base
#     serialize :days, WeekSauce
#   end
#   
#   workout = Workout.find_by_kind("Weights")
#   workout.days.inspect #=> "20: Tuesday, Thursday"
#   
#   workout.days.set!(:tuesday, :thursday) # sets only those days
#   workout.save
# 
# The underlying `days` database column can be either a string or integer type.
# 
class WeekSauce
  MAX_VALUE = 2**7 - 1
  DAY_NAMES = %w(sunday monday tuesday wednesday thursday friday saturday).map(&:to_sym).freeze
  DAY_BITS  = Hash[ DAY_NAMES.zip(Array.new(7) { |i| 2**i }) ].freeze
  
  class << self
    # ActiveRecord attribute serialization support
    # 
    # Create a WeekSauce instance from a stringified integer
    # bitmask. The value will be clamped (see #new)
    def load(string)
      self.new(string.to_i)
    rescue NoMethodError => err
      self.new
    end
    
    # ActiveRecord attribute serialization support
    # 
    # Dump a WeekSauce instance to a stringified bitmask value
    def dump(instance)
      if instance.is_a?(self)
        instance.to_i.to_s
      else
        "0"
      end
    end
  end
  
  # Init a new WeekSauce instance. If +value+ is omitted, the new
  # instance will default to a bitmask of zero, i.e. no days set.
  # 
  # If a +value+ argument is given, +to_i+ will be called on it,
  # and the resulting integer will be clamped to 0..127
  def initialize(value = nil)
    @value = [[0, value.to_i].max, MAX_VALUE].min
  end
  
  # Compare this instance against another instance or a Fixnum
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
  
  # Create the day=, day, and day? methods
  DAY_BITS.each do |day, bit|
    define_method(day) do
      get_bit bit
    end
    alias_method :"#{day.to_s}?", day
    
    define_method("#{day.to_s}=") do |bool|
      set_bit bit, bool
    end
  end
  
  # Returns +true+ if the given day is set, +false+ if it isn't,
  # and +nil+ if the argument was invalid.
  # 
  # The +wday+ argument can be
  # - a Fixnum from 0 (Sunday) to 6 (Saturday),
  # - a day-name symbol, e.g. +:tuesday+, +:friday+,
  # - a day-name string (case-insensitive), e.g. <tt>"Monday"</tt>, <tt>"sunday"</tt>
  # - a Time object, or
  # - a Date object
  def [](wday)
    get_bit coerce_to_bit(wday)
  end
  
  # Set or unset the given day. See #[] for possible +wday+ values.
  # Invalid +wday+ values are ignored.
  def []=(wday, bool)
    set_bit coerce_to_bit(wday), bool
  end
  
  # Set the given days. Like #[], arguments can be symbols, Fixnums,
  # or Date/Time objects
  def set(*days)
    days.each do |day|
      self[day] = true
    end
  end
  
  # Exclusive version of #set. Clears the week, and sets only
  # the days passed. Returns +self+
  def set!(*days)
    blank!
    set(*days)
    self
  end
  
  # Unset the given days. Like #[], arguments can be symbols,
  # Fixnums, or Date/Time objects
  def unset(*days)
    days.each do |day|
      self[day] = false
    end
  end
  
  # Exclusive version of #unset. Sets all days to true and
  # then unsets days passed. Returns +self+
  def unset!(*days)
    all!
    unset(*days)
    self
  end
  
  # Set all days to +false+. Returns +self+
  def blank!
    @value = 0
    self
  end
  
  # Set all days to +true+. Returns +self+
  def all!
    @value = MAX_VALUE
    self
  end
  
  # Returns the raw bitmask integer
  def to_i
    @value
  end
  
  # Returns an array of "set" day names as symbols
  def to_a
    DAY_NAMES.select { |day| self[day] }
  end
  
  # Returns a hash where the keys are the week's 7 days
  # as symbols, and the values are booleans
  def to_hash
    Hash[ DAY_NAMES.map { |day| [day, self[day]] } ]
  end
  
  # Returns the number of "set" days
  def count
    to_a.count
  end
  
  # Returns a string with the bitmask value and a list of
  # "set" days, or a simple message if all/no days are set
  def inspect
    if blank?
      "0: No days set"
    elsif all?
      "#{MAX_VALUE}: All days set"
    else
      list = to_a.map { |day| day.to_s.sub(/./, &:upcase) }.join(", ")
      "#{@value}: #{list}"
    end
  end
  
  # Return the next date matching the bitmask, or +nil+ if the
  # week is blank.
  # 
  # If no +from_date+ argument is given, it'll default to
  # <tt>Date.current</tt> if ActiveSupport is available,
  # otherwise it'll use <tt>Date.today</tt>.
  # 
  # If +from_date+ argument can be a +Date+ or a +Time+ object
  # (the latter will be converted using +#to_date+)
  # 
  # If +from_date+ is given, #next_date will return the first
  # matching date from - and including - +from_date+
  def next_date(from_date = nil)
    return nil if blank?
    from_date ||= if Date.respond_to?(:current)
      Date.current
    else
      Date.today
    end
    from_date = from_date.to_date
    until self[from_date.wday]
      from_date = from_date.succ
    end
    from_date.dup
  end
  
  # Return all dates in the given +date_range+ that match the
  # bitmask. If the week's blank, an empty array will be
  # returned.
  # 
  # Note that the range is converted to an array, which
  # is then filtered, so if the range is "backwards" (high to
  # low) an empty array will be returned
  def dates_in(date_range)
    return [] if blank?
    date_range.to_a.select { |date| self[date.wday] }
  end
  
  protected
  
    def get_bit(bit) #:nodoc:
      if DAY_BITS.values.include?(bit)
        @value & bit > 0
      end
    end
    
    def set_bit(bit, set) #:nodoc:
      if DAY_BITS.values.include?(bit)
        if set
          @value = @value | bit
        else
          @value = @value & (MAX_VALUE ^ bit)
        end
      end
    end
    
    def coerce_to_bit(wday) #:nodoc:
      case wday
      when Symbol
        DAY_BITS[wday]
      when Fixnum, /\A[0-6]\Z/
        wday = wday.to_i
        (0..6).include?(wday) ? 2**wday : nil
      when Date, Time
        2**wday.wday
      when /\A(sun|mon|tues|wednes|thurs|fri|satur)day\Z/i
        DAY_BITS[wday.downcase.to_sym]
      end
    end
  
end
