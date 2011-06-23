class AvalonControl::MotionControlTask 
    provides Srv::AUVMotionController
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

Cmp::ControlLoop.specialize 'controller' => AvalonControl::MotionControlTask do
    add Srv::OrientationWithZ, :as => 'pose'
    connect pose.orientation_z_samples => controller.pose_samples
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
    add Srv::Pose
    autoconnect
end

