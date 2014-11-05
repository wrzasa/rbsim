class Numeric

  #
  # Time units
  #

  RBSIM_JIFFIES_PER_SECOND = 1000000
  def seconds
    self * RBSIM_JIFFIES_PER_SECOND
  end

  def miliseconds
    (self.seconds / 1000).to_i
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
    self.in_seconds / 1000
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
