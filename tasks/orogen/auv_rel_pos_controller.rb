class AuvRelPosController::Task

    def configure
        super

    orogen_task.rel_heading = 1
    orogen_task.rel_z = 0
    #orogen_task.fixed_z = -2.3
    orogen_task.timeout = 30

    pid_settings = orogen_task.controller_x
    pid_settings.zero!
    pid_settings.Ts = 0.01
    pid_settings.K = 1
    pid_settings.Ti = 0.0
    pid_settings.Td = 0
    pid_settings.YMin = -0.8 #-0.2
    pid_settings.YMax = 0.8 #0.2
    orogen_task.controller_x = pid_settings

    pid_settings = orogen_task.controller_y
    pid_settings.zero!
    pid_settings.Ts = 0.01
    pid_settings.K = 8
    pid_settings.Ti = 0.0
    pid_settings.Td = 1 
    pid_settings.YMin = -2 #-0.2
    pid_settings.YMax = 2  #0.2
    orogen_task.controller_y = pid_settings
    end

end
