# Main planner. A planner of this model is automatically added
# to the interface planner list. For Avalon it should provide
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

def deg_to_rad(angle)
    angle * Math::PI / 180
end

def rad_to_deg(angle)
    angle * 180 / Math::PI
end

def time_over?(start_time, duration)
    return (Time.now - start_time) > duration
end


def robot_name?(name)
    return Roby.app.robot_name == name.to_s
end

