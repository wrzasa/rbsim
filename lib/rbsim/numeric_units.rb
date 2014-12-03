#
# This file extends Ruby Numeric class by methods
# used in RBSim to desciribe units of time,
# data volume and network speed.
#
# Native data volume unit is one bit
# Native network speed unit is one bit per second
# Time unit is one jiffie, defined by Numric::RBSIM_JIFFIES_PER_SECOND
class Numeric

  #
  # Time units
  #


  # Defines unit of time -- jiffie is the smallest
  # time unit that can be accounted by simulator
  RBSIM_JIFFIES_PER_SECOND = 1000000

  def seconds
    self * RBSIM_JIFFIES_PER_SECOND
  end

  def miliseconds
    self.seconds / 1000
  end

  def microseconds
    self.miliseconds / 1000
  end

  def minutes
    self.seconds * 60
  end

  def hours
    self.minutes * 60
  end

  def days
    self.hours * 24
  end

  def in_seconds
    self / RBSIM_JIFFIES_PER_SECOND
  end

  def in_miliseconds
    self * 1000 / RBSIM_JIFFIES_PER_SECOND
  end

  def in_microseconds
    self * 1000 * 1000 / RBSIM_JIFFIES_PER_SECOND
  end

  def in_minutes
    self.in_seconds / 60
  end

  def in_hours
    self.in_minutes / 60
  end

  def in_days
    self.in_hours / 24
  end

  #
  # Data volume units
  #

  def bytes
    self * 8
  end

  def in_bytes
    self / 8
  end

  def in_bits
    self
  end

  def bits
    self
  end

  #
  # Network throuput units
  #

  def bps
    self
  end

  def Bps
    self * 8
  end

  def in_bps
    self
  end

  def in_Bps
    self / 8
  end
end
