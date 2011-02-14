class Skid4Control::Controller
    provides Srv::ActuatorController
end

class Skid4Control::SimpleController
    provides Srv::Motion2DController

    def configure
        super

        orogen_task.wheel_radius = 0.178
        orogen_task.track_width  = 0.515
    end
end

class Skid4Control::FourWheelController
    provides Srv::FourWheelController
end


