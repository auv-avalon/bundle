class MainPlanner
    method(:quick_navigate) do
        DYNAMIC_YAW = 10
        TOLERANCE_YAW = 0.2

        wp1 = Types::Base::Waypoint.new
        wp1.position = Eigen::Vector3.new(20.0, 10.0, -3.0)
        wp1.heading = DYNAMIC_YAW
        wp1.tol_position = 2.0
        wp1.tol_heading = TOLERANCE_YAW

        wp2 = Types::Base::Waypoint.new
        wp2.position = Eigen::Vector3.new(20.0, -10.0, -3.0)
        wp2.heading = DYNAMIC_YAW
        wp2.tol_position = 2.0
        wp2.tol_heading = TOLERANCE_YAW

        trajectory = []
        trajectory << wp1
        trajectory << wp2

        navigate_to(:waypoints => trajectory, :keep_time => 60.0)
    end
end
