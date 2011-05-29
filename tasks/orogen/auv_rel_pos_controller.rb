class AuvRelPosController::Task
    def configure
        super

        orogen_task.rel_heading = 1
        orogen_task.rel_z = 0
        orogen_task.fixed_z = -2.3
        orogen_task.timeout = 30

        pid_settings = orogen_task.controller_x
        pid_settings.zero!
        pid_settings.Ts = 0.01
        pid_settings.K = 0.5
        pid_settings.Ti = 0.0
        pid_settings.Td = 1
        pid_settings.YMin = -0.8 #-0.2
        pid_settings.YMax = 0.8 #0.2
        orogen_task.controller_x = pid_settings

        pid_settings = orogen_task.controller_y
        pid_settings.zero!
        pid_settings.Ts = 0.01
        pid_settings.K = 0.1
        pid_settings.Ti = 0.001
        pid_settings.Td = 2 
        pid_settings.YMin = -0.4 #-0.2
        pid_settings.YMax = 0.4 #0.2
        orogen_task.controller_y = pid_settings
    end

    provides Srv::Command
end

# NOTE: the 'controller' => Bla part of the specialization should not be needed,
# but is as of today (29.05.2011)
Cmp::ControlLoop.specialize 'command' => AuvRelPosController::Task do
    overload 'controller', Srv::AUVMotionController
    export command.position_command
    connect command.motion_command => controller.command
end
