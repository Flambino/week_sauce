require 'spec_helper'
require 'active_support/time'

describe WeekSauce do
  
  let(:days) do
    # Sunday => 0 similar to Time#wday
    %w(sunday monday tuesday wednesday thursday friday saturday).map(&:to_sym)
  end
  
  # The maximum value of the bitmask (2**7 - 1)
  let(:max) { 127 }
  
  describe "initializer" do
    it "defaults to zero/blank" do
      WeekSauce.new.to_i.should == 0
      WeekSauce.new(nil).to_i.should == 0
    end
    
    it "accepts valid numbers" do
      WeekSauce.new(0).to_i.should   == 0
      WeekSauce.new(64).to_i.should  == 64
      WeekSauce.new(max).to_i.should == max
    end
    
    it "clamps input" do
      WeekSauce.new(-100).to_i.should == 0
      WeekSauce.new(2**9).to_i.should == max
    end
  end
  
  describe "interrogation" do
    context "with no days set" do
      let(:week) { WeekSauce.new }
      it "returns correct values" do
        week.blank?.should  be_true
        week.any?.should    be_false
        week.many?.should   be_false
        week.one?.should    be_false
        week.all?.should    be_false
        days.each do |day|
          week.send("#{day.to_s}?").should be_false
        end
      end
    end
    
    context "with only one day set" do
      let(:week) { WeekSauce.new(16) } # Thursday
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_false
        week.one?.should    be_true
        week.all?.should    be_false
        days.each do |day|
          week.send("#{day.to_s}?").should == (day == :thursday)
        end
      end
    end
    
    context "with more than one day set" do
      let(:week) { WeekSauce.new(31) } # Sunday-Thursday
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_true
        week.one?.should    be_false
        week.all?.should    be_false
        days[0..4].each do |day|
          week.send("#{day.to_s}?").should be_true
        end
        days[5..6].each do |day|
          week.send("#{day.to_s}?").should be_false
        end
      end
    end
    
    context "with all days set" do
      let(:week) { WeekSauce.new(max) }
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_true
        week.one?.should    be_false
        week.all?.should    be_true
        days.each do |day|
          week.send("#{day.to_s}?").should be_true
        end
      end
    end
  end
  
  describe "writing" do
    describe "using bracket syntax" do
      let(:week) { WeekSauce.new }
      it "works with integers" do
        week[0] = true
        week[0] = true # repeated on purpose to expose bitwise XOR errors
        week.to_i.should == 1
        week[6] = true
        week.to_i.should == 65
      end
      
      it "ignores out-of-bounds integers" do
        week[-1] = true
        week.to_i.should == 0
        week[7] = true
        week.to_i.should == 0
      end
      
      it "works with day-name symbols" do
        week[:sunday] = true
        week.to_i.should == 1
        week[:wednesday] = true
        week.to_i.should == 9
      end
      
      it "ignores non-sensical symbols" do
        week[:foo] = true
        week.to_i.should == 0
      end
      
      it "works with Time and TimeWithZone objects" do
        week[Time.now] = true
        week.to_i.should == 2**Time.now.wday
        
        Time.zone = ActiveSupport::TimeZone["Copenhagen"]
        time = Time.zone.now
        week[time] = true
        week.to_i.should == 2**time.wday
      end
      
      it "works with Date and DateTime objects" do
        date = Date.today
        week[date] = true
        week.to_i.should == 2**date.wday
        
        date = DateTime.now
        week[date] = true
        week.to_i.should == 2**date.wday
      end
      
      it "ignores unhandled argument types" do
        week["string"] = true
        week.to_i.should == 0
      end
    end
    
    it "works with day-name setters" do
      week = WeekSauce.new
      week.sunday = true
      week.to_i.should == 1
      week.saturday = true
      week.to_i.should == 65
    end
  end
  
  describe "reading" do
    describe "using bracket syntax" do
      let(:week) { WeekSauce.new(42) } # Monday, Wednesday, Friday
      
      it "works with integers" do
        week[0].should be_false
        week[1].should be_true
        week[2].should be_false
        week[3].should be_true
        week[4].should be_false
        week[5].should be_true
        week[6].should be_false
      end
      
      it "returns nil for out-of-bounds integers" do
        week[-1].should be_nil
        week[7].should be_nil
      end
      
      it "works with day-name symbols" do
        week[:sunday].should be_false
        week[:monday].should be_true
        week[:tuesday].should be_false
        week[:wednesday].should be_true
        week[:thursday].should be_false
        week[:friday].should be_true
        week[:saturday].should be_false
      end
      
      it "returns nil for non-sensical symbols" do
        week[:foo].should be_nil
      end
      
      it "works with Time and TimeWithZone objects" do
        time = Time.now
        time = time + (3 - time.wday).days # set to Wednesday
        week[time].should be_true
        time = time + 1.day # set to Thursday
        week[time].should be_false
        
        Time.zone = ActiveSupport::TimeZone["Copenhagen"]
        time = Time.zone.now
        time = time + (3 - time.wday).days
        week[time].should be_true
        time = time + 1.day # set to Thursday
        week[time].should be_false
      end
      
      it "works with Date and DateTime objects" do
        date = Date.today
        date = date + (3 - date.wday).days # set to Wednesday
        week[date].should be_true
        date = date + 1.day # set to Thursday
        week[date].should be_false
        
        date = DateTime.now
        date = date + (3 - date.wday).days # set to Wednesday
        week[date].should be_true
        date = date + 1.day # set to Thursday
        week[date].should be_false
      end
      
      it "returns nil for unhandled argument types" do
        week["string"].should be_nil
      end
    end
    
    it "works with day-name getters" do
      week = WeekSauce.new(42)
      week.sunday.should    be_false
      week.monday.should    be_true
      week.tuesday.should   be_false
      week.wednesday.should be_true
      week.thursday.should  be_false
      week.friday.should    be_true
      week.saturday.should  be_false
    end
  end
  
  describe "blank! method" do
    it "clears the instance" do
      week = WeekSauce.new(max)
      week.blank!
      week.to_i.should == 0
    end
    
    it "returns self" do
      week = WeekSauce.new
      week.blank!.should be(week)
    end
  end
  
  describe "all! method" do
    it "sets all bits" do
      week = WeekSauce.new
      week.all!
      week.to_i.should == max
    end
    
    it "returns self" do
      week = WeekSauce.new
      week.all!.should be(week)
    end
  end
  
  describe "utilities" do
    describe "to_a" do
      it "returns an array" do
        WeekSauce.new(42).to_a.should include(:monday, :wednesday, :friday)
        WeekSauce.new.to_a.should == []
      end
    end
    
    describe "to_hash" do
      it "to_hash returns a hash" do
        WeekSauce.new(42).to_hash.should == {
          sunday:    false,
          monday:    true,
          tuesday:   false,
          wednesday: true,
          thursday:  false,
          friday:    true,
          saturday:  false
        }
      end
    end
    
    describe "dup" do
      let(:week) { WeekSauce.new(rand(0..127)) }
      
      it "dups to a new instance" do
        week.dup.to_i.should == week.to_i
        week.dup.should_not be(week)
      end
    end
  end
  
  describe "comparison" do
    let(:week) { WeekSauce.new(42) }
    
    it "works with fixnums" do
      week.should     == 42
      week.should_not == 43
    end
    
    it "works with other instances" do
      week.should     == WeekSauce.new(42)
      week.should_not == WeekSauce.new
    end
  end
  
  describe "date calculation" do
    describe "next_date" do
      let(:week) { WeekSauce.new(2**3) } # Wednesday
      
      it "finds next date from today if not argument is passed" do
        date = Date.today
        offset = 3 - date.wday
        offset += 7 if offset < 0
        week.next_date.should == date + offset.days
      end
      
      it "finds next date from a given day" do
        date = Time.parse "2013-04-01" # April fool's (also a happens to be a Monday)
        week.next_date(date).should == date.to_date + 2.days
      end
      
      it "returns a duplicate of the from argument if it matches" do
        week = WeekSauce.new(3) # Monday
        date = Date.parse "2013-04-01"
        result = week.next_date(date)
        result.should == date
        result.should_not be(date)
      end
      
      it "returns nil if the week's blank" do
        WeekSauce.new.next_date.should be_nil
      end
    end
    
    describe "dates_in" do
      it "returns an array of dates in a given range" do
        week = WeekSauce.new
        starts = Date.today
        ends   = starts + 3.weeks
        week[starts] = true
        dates = week.dates_in(starts..ends)
        dates.length.should == 4
        dates.first.should == starts
        dates.last.should == ends
      end
      
      it "returns an empty array if the week's blank" do
        week = WeekSauce.new
        starts = Date.today
        ends   = starts + 3.weeks
        week.dates_in(starts...ends).empty?.should be_true
      end
    end
  end
  
  describe "serialization" do
    describe "load" do
      it "loads from a string" do
        week = WeekSauce.load("127")
        week.to_i.should == 127
      end
      
      it "clamps value" do
        WeekSauce.load("1027").to_i.should == 127
        WeekSauce.load("-127").to_i.should == 0
      end
      
      it "absorbs conversion errors" do
        WeekSauce.load([]).to_i.should == 0
      end
    end
    
    describe "dump" do
      it "dumps to a string" do
        week = WeekSauce.new(42)
        WeekSauce.dump(week).should == "42"
      end
      
      it "defaults to outputting zero" do
        WeekSauce.dump(123).should == "0"
      end
    end
  end
  
end
