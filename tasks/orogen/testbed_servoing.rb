class TestbedServoing::Task 

    def configure
        super
	orogen_task.timeout = 2 
	orogen_task.buoy_diameter = 50 

	pid_settings = orogen_task.x_pid
	pid_settings.zero!
	pid_settings.p = 10 
#	pid_settings.d = 0.0025
    	pid_settings.min = -1 #-0.2
	pid_settings.max = 1 #0.2
	orogen_task.x_pid = pid_settings

	pid_settings = orogen_task.y_pid
	pid_settings.zero!
	pid_settings.p = -10 
#	pid_settings.d = 0.05
    	pid_settings.min = -1 # -0.4
	pid_settings.max = 1 #0.4
	orogen_task.y_pid = pid_settings
	
	pid_settings = orogen_task.z_pid
	pid_settings.zero!
	pid_settings.p = 10
#	pid_settings.d = 0.05
    	pid_settings.min = -1 # -0.4
	pid_settings.max = 1 #0.4
	orogen_task.z_pid = pid_settings
	

    end

end


