require 'spec_helper'

describe "Numeric units" do

  let(:jiffies) { Numeric::RBSIM_JIFFIES_PER_SECOND }

  shared_examples "has correct units" do
      # volume units
      its(:bits)      { should eq subject }
      its(:bytes)     { should eq subject * 8 }
      its(:in_bits)   { should eq subject }
      its(:in_bytes)  { should eq subject / 8 }

      # network units
      its(:bps)     { should eq subject.to_f / jiffies}
      its(:Bps)     { should eq subject.to_f * 8 / jiffies }
      its(:in_bps)  { should eq subject * jiffies }
      its(:in_Bps)  { should eq subject / 8 * jiffies }

      # time units
      its(:seconds)         { should eq subject * jiffies }
      its(:miliseconds)     { should eq subject * jiffies / 1000 }
      its(:microseconds)    { should eq subject * jiffies / 1000000 }
      its(:minutes)         { should eq subject * jiffies * 60 }
      its(:hours)           { should eq subject * jiffies * 60 * 60 }
      its(:days)            { should eq subject * jiffies * 60 * 60 * 24 }

      its(:in_seconds)      { should eq subject / jiffies }
      its(:in_miliseconds)  { should eq subject * 1000 / jiffies }
      its(:in_microseconds) { should eq subject * 1000 * 1000 / jiffies }
      its(:in_minutes)      { should be_within(1.0/jiffies).of( subject / (jiffies * 60) ) }
      its(:in_hours)        { should be_within(1.0/jiffies).of( subject / (jiffies * 60 * 60) ) }
      its(:in_days)         { should be_within(1.0/jiffies).of( subject / (jiffies * 60 * 60 * 24) ) }
  end

  describe 128 do
    include_examples 'has correct units'
  end

  describe 1.5 do
    include_examples 'has correct units'
  end

  describe 50000 do
    include_examples 'has correct units'
  end

end
