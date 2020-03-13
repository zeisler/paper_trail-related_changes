class ActiveRecord::Base
  def self.relationally_independent=(value)
    @relationally_independent = value
  end

  def self.relationally_independent?
    if instance_variable_defined? :@relationally_independent
      @relationally_independent
    else
      true
    end
  end
end
