require 'fast-tcpn'
require 'rbsim/dsl'
require 'rbsim/hlmodel'
require 'rbsim/simulator'
require 'rbsim/statistics'
require 'rbsim/numeric_units'
require 'rbsim/version'

module RBSim
  def self.stats_read(file)
    Marshal.load File.read(file)
  end
end
