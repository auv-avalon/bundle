# Main planner. A planner of this model is automatically added
# to the interface planner list. For Avalon it should provides
# global utility functions used in plannning scripting.
module Plan
    class << self
        attr_accessor :logger
    end
    extend Logger::Forward

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @logger.formatter = Roby.logger.formatter
    @logger.progname = "MainPlanner"
end

class MainPlanner < Roby::Planning::Planner
end

# normalize current angle to range between PI and -PI
def normalize_angle(angle)
    if angle > Math::PI
        angle - 2 * Math::PI
    elsif angle < -Math::PI
        angle + 2 * Math::PI
    else
        angle
    end
end

def time_over?(start_time, duration)
    return (Time.now - start_time) > duration
end



