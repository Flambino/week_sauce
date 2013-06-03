# WeekSauce [![Code Climate](https://codeclimate.com/github/Flambino/week_sauce.png)](https://codeclimate.com/github/Flambino/week_sauce)

WeekSauce is a simple class that functions as a days-of-the-week bitmask. Useful for things that repeat weekly, and/or can occur on one or more days of the week.

It was extracted from a Rails app, and is primarily intended to used as an ActiveRecord attribute serializer, but it should work fine outside of Rails too.

## Installation

It's a gem, so:

    gem install week_sauce

or, if you're using Bundler, put this in your Gemfile:

    gem 'week_sauce'

## The Basics

``` ruby
week = WeekSauce.new(16) # init with bitmask (optional)
week.blank?     #=> false
week.one?       #=> true
week.thursday?  #=> true

week = WeekSauce.new     # defaults to a zero-bitmask
week.blank? #=> true

# Mark the weekend
week.set(:saturday, :sunday)

from = Time.parse("2013-04-01") # A Monday
week.next_date(from)            #=> Sat, 06 Apr 2013

week.dates_in(from..from + 1.week) => [Sat, 06 Apr 2013 , Sun, 07 Apr 2013]
```

## Usage with ActiveRecord

``` ruby
class Workout < ActiveRecord::Base
  serialize :days, WeekSauce
end

workout = Workout.find_by_kind("Weights")
workout.days.inspect #=> "20: Tuesday, Thursday"

workout.days.set!(:tuesday, :thursday) # sets only those days
workout.save
```

The underlying `days` database column can be either a string or integer type.

## API

Individual days can be set and read using Fixnums, symbols or Date/Time objects. Additionally, there are named methods for getting and setting each of the week's days:

``` ruby
time = Time.parse("2013-04-01") # A Monday

# These are all equivalent
week.monday        = true
week[:monday]      = true
week[1]            = true
week[time]         = true
week[time.to_date] = true

# And these are equivalent too
week.monday        #=> true
week.monday?       #=> true
week[:monday]      #=> true
week[1]            #=> true
week[time]         #=> true
week[time.to_date] #=> true
```

_Note that similar to `Date#wday`, Sunday is `0`, Monday is `1` and so forth._

Several days can be set or unset using the so-named methods:

``` ruby
# arguments can also be Fixnums or Date/Time objects
week.set(:monday, :wednesday)    # set those days to true
week.unset(:monday, :wednesday)  # set those days to false
```

These also have "exclusive" versions:

``` ruby
week.set!(:monday, :wednesday)   # sets *only* those days to true, all others to false
week.unset!(:monday, :wednesday) # sets *only* those days to false, all others to true
```

There are also a few value-checking methods:

``` ruby
week.blank?  # true if no days are set
week.one?    # true if exactly 1 day is set
week.any?    # true if at least 1 day is set
week.many?   # true if at least 2 days are set
week.all?    # true if all days are set

# The == comparison operator works with other WeekSauce objects and Fixnums
week == other_week #=> true if the bitmask values match
week == 123        #=> true if the bitmask value == 123
```

And a couple of methods to find dates matching the week's bitmask:

``` ruby
week.dates_in(from..to)   # find matching dates in a range of dates

week.next_date            # finds next matching date from today
week.next_date(some_date) # finds next matching date from (and including) some_date
```

If ActiveSupport's time zone support is available, `next_date` with no argument will default to the time zone-aware `Date.current` instead of `Date.today`.

Lastly, a few utility methods:

``` ruby
week.to_i    #=> the raw integer bitmask
week.to_a    #=> array of the selected days' names, e.g. [:monday, :thursday]
week.to_hash #=> hash with day names as keys, and the day's boolean state as value
week.inspect #=> string describing the bitmask values and days, e.g. "3: Sunday, Monday"
```

## Odds and ends

The gem was extracted from a Rails 3.2 app, and requires Ruby 1.9.3 or higher. The requirement is undoubtedly overkill, but the code currently uses the 1.9+ hash syntax. It could probably be converted very easily though (feel free!).

The code has good test coverage (using RSpec), but hasn't been tested outside of Ruby 1.9.3.
