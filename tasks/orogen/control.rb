class Control::PIVController
    provides Srv::Motion2DController
    provides Srv::FourWheelController
end

class Control::PIVController
    def configure
        super
        orogen_task.front_back_offset_on = true
        orogen_task.experiment_on = false
        orogen_task.forward_speed = 0.2
        orogen_task.offset_on = false
        orogen_task.offset_wheel_FL = 0.0
        orogen_task.offset_wheel_FR = 0.0
        orogen_task.offset_wheel_RL = 0.0
        orogen_task.offset_wheel_RR = 0.0
    end
end     

