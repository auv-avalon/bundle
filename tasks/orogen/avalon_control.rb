class AvalonControl::MotionControlTask 
    provides Srv::AUVMotionController

    USE_INTEGRAL=true
    USE_DEPTH_CONTROLLER=true

    def configure
        super
	
	orogen_task.z_coupling_factor = -0.19
	orogen_task.y_coupling_factor = 0.10
	orogen_task.y_factor = 1 
	orogen_task.x_factor = 1 
	
	pid_settings = orogen_task.z_pid
	pid_settings.zero!
	#if USE_DEPTH_CONTROLLER
	pid_settings.p = -1.5
	if USE_INTEGRAL
		pid_settings.i = -0.05
	end
	pid_settings.d = 1 
	pid_settings.min = -1
	pid_settings.max = 1
	#end
	orogen_task.z_pid = pid_settings
	
	pid_settings.zero!
	pid_settings.p = -0.6 # -0.8 
	if USE_INTEGRAL
	    pid_settings.i = -0.001
	end
	pid_settings.d = -2
	pid_settings.min = -0.8
	pid_settings.max = 0.8
	orogen_task.heading_pid = pid_settings
	
	pid_settings.zero!
	pid_settings.p = 2
	if USE_INTEGRAL
		pid_settings.i = 0.2
	end
	pid_settings.d = 1
	pid_settings.min = -1
	pid_settings.max = 1
	orogen_task.pitch_pid = pid_settings
	orogen_task.pitch_target = 7.0/180.0*Math::PI


    end

end


class AvalonControl::PositionControlTask 
#    provides Srv::AUVMotionController

    def configure
        super
	
	pid_settings = orogen_task.x_pid
	pid_settings.zero!
	pid_settings.p = 0.1
	#pid_settings.p = 0.1
#	pid_settings.d = 0.0025
    	#pid_settings.min = -0.2
	#pid_settings.max = 0.2
    	pid_settings.min = -0.005
	pid_settings.max = 0.005
	orogen_task.x_pid = pid_settings

	pid_settings = orogen_task.y_pid
	pid_settings.zero!
	pid_settings.p = -0.2
	#pid_settings.p = 0.2
#	pid_settings.d = 0.05
    	#pid_settings.min =  -0.4
	#pid_settings.max = 0.4
    	pid_settings.min =  -0.08
	pid_settings.max = 0.08
	orogen_task.y_pid = pid_settings

    end
end
