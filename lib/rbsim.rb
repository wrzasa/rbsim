require 'tcpn'
require 'dsl'
require 'hlmodel'
require 'simulator'
require 'statistics'
require 'numeric_units'

module RBSim
  def self.stats_read(file)
    Marshal.load File.read(file)
  end
end
