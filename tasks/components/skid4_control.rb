class Skid4Control::Controller
    data_service ActuatorController
end

class Skid4Control::SimpleController
    data_service Motion2DController

    def configure
        super

        orogen_task.wheel_radius = 0.178
        orogen_task.track_width  = 0.515
    end
end

class Skid4Control::FourWheelController
    data_service FourWheelController
end


