# WeekSauce

WeekSauce is a simple class that functions as a days-of-the-week bitmask.
Useful for things that repeat weekly, and/or can occur or one or more days
of the week.

Extracted from a Rails app, it's intended to be used an ActiveRecord
attribute serializer, but it should work fine outside of Rails.

## Basic usage

    week = WeekSauce.new(16) # set a specific bitmask
    week.blank?     #=> false
    week.one?       #=> true
    week.thursday?  #=> true
    
    week = WeekSauce.new     # defaults to a zero-bitmask
    week.blank? #=> true
    
    # Mark off the weekend
    week.set(:saturday, :sunday)
    
    from = Time.parse("2013-04-01") # A Monday
    week.next_date(from)            #=> "2013-04-06" (a Saturday)
    
    week.dates_in(from..from + 1.week) => ["2013-04-06", "2013-04-07"]

## Rails usage

    class Workout < ActiveRecord::Base
      serialize :days, WeekSauce
    end
    
    workout = Workout.find_by_kind("Weights")
    workout.days.to_s #=> "Monday, Wednesday"
    workout.days.set!(:tuesday, :thursday) # sets only those days
    workout.save

## API

Individual days can be set and read using Fixnums, symbols or Date/Time
objects. Additionally, there are named methods for getting and setting
each of the week's days:

    # These are all equivalent
    week.monday   = true
    week[:monday] = true
    week[1]       = true
    
    time = Time.parse("2013-04-01") # A Monday
    week[time] = true
    week[time.to_date] = true
    
    # And these are equivalent too
    week.monday   #=> true
    week.monday?  #=> true
    week[:monday] #=> true
    week[1]       #=> true
    week[time]    #=> true

_Note that similar to `Date#wday`, Sunday is `0`, Monday is `1` and so forth._

There are also a few value-checking methods:

    week.blank? # true if no days are set
    week.one?   # true if exactly 1 day is set
    week.any?   # true if at least 1 day is set
    week.many?  # true if at least 2 days are set
    week.all?   # true if all days are set

Several days can be set or unset using the so-named methods:

    # arguments can also be Fixnums or Date/Time objects
    week.set(:monday, :wednesday)    # set those days to true
    week.unset(:monday, :wednesday)  # set those days to false

These also have "exclusive" versions

    week.set!(:monday, :wednesday)   # sets *only* those days to true, all others to false
    week.unset!(:monday, :wednesday) # set *only* those days to false, all others to true

Lastly, dates matching the week's bitmask can be calculated

    week.dates_in(from..to)   # find matching dates in a range
    
    week.next_date            # finds next matching date from today
    week.next_date(some_date) # finds next matching date from (and including) some_date

If ActiveSupport's time zone support is available, `next_date` with no argument will default to the time zone-aware `Date.current` instead of `Date.today`.
