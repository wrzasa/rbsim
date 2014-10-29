require 'hlmodel'
require 'tcpn'

module RBSim
  class ProcessToken < HLModel::Process
    include TCPN::TokenMethods
  end
end
