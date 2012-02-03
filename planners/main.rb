# Main planner. A planner of this model is automatically added
# to the interface planner list. For Avalon it should provides
# global utility functions used in plannning scripting.
class MainPlanner < Roby::Planning::Planner

    # use a defined data_reader 'orientation_reader' for fetching current yaw
    def get_current_yaw(orientation_reader)
        yaw = nil
        poll do
            if o = orientation_reader
                yaw = o.orientation.yaw
                transition!
            end
        end
        yaw
    end

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
