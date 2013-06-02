require 'spec_helper'
require 'active_support/time'

describe WeekSauce do
  
  let(:days) do
    # Sunday => 0 similar to Time#wday
    %w(sunday monday saturday wednesday thursday friday saturday).map(&:to_sym)
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
        week.single?.should be_false
        week.all?.should    be_false
      end
    end
    
    context "with only one day set" do
      let(:week) { WeekSauce.new(16) }
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_false
        week.single?.should be_true
        week.all?.should    be_false
      end
    end
    
    context "with more than one day set" do
      let(:week) { WeekSauce.new(31) }
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_true
        week.single?.should be_false
        week.all?.should    be_false
      end
    end
    
    context "with all days set" do
      let(:week) { WeekSauce.new(max) }
      it "returns correct values" do
        week.blank?.should  be_false
        week.any?.should    be_true
        week.many?.should   be_true
        week.single?.should be_false
        week.all?.should    be_true
      end
    end
  end
  
  describe "bracket setter" do
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
  
  describe "bracket getter" do
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
end
