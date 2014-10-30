require 'hlmodel'
require 'tcpn'

module RBSim
  module Tokens

    class ProcessToken < HLModel::Process
      include TCPN::TokenMethods
    end

  end
end
