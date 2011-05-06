class AuvRelPosController::Task

    def configure
        super

    orogen_task.rel_heading = false
    orogen_task.timeout = 2

    pid_settings = orogen_task.controller_x
    pid_settings.zero!
    pid_settings.Ts = 0.01
    pid_settings.K = 0.5
    pid_settings.Ti = 0.1
    pid_settings.Td = 10
    pid_settings.YMin = -0.8 #-0.2
    pid_settings.YMax = 0.8 #0.2
    orogen_task.controller_x = pid_settings

    pid_settings = orogen_task.controller_y
    pid_settings.zero!
    pid_settings.Ts = 0.01
    pid_settings.K = 0.5
    pid_settings.Ti = 0.1
    pid_settings.Td = 10
    pid_settings.YMin = -0.4 #-0.2
    pid_settings.YMax = 0.4 #0.2
    orogen_task.controller_y = pid_settings
    end

end
