require 'spec_helper'

describe WeekSauce do
  
  let(:days) do
    # Sunday == 0 similar to Date#wday
    %w(sunday monday saturday wednesday thursday friday saturday).map(&:to_sym)
  end
  
  # The maximum value of the bitmask (127)
  let(:max) { 2**7 - 1 }
  
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
  
end
