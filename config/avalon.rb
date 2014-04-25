#Front Machine
#Syskit.conf.process_server 'front','192.168.128.50' #, :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'
Syskit.conf.process_server 'back','192.168.128.51' #, :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'
#Syskit.conf.process_server 'front','localhost', :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'


Syskit.conf.use_deployment 'dynamixel'
Syskit.conf.use_deployment 'front_camera'
Syskit.conf.use_deployment 'bottom_camera'
Syskit.conf.use_deployment 'left_unicap_camera'
Syskit.conf.use_deployment 'right_unicap_camera'
Syskit.conf.use_deployment 'buoy_detector'
Syskit.conf.use_deployment 'pipeline_follower', :on => 'back'
Syskit.conf.use_deployment 'taskmon_front'
Syskit.conf.use_deployment 'sonar_wall_hough'
Syskit.conf.use_deployment 'lights'
Syskit.conf.use_deployment 'low_level'
Syskit.conf.use_deployment 'line_scanner'
Syskit.conf.use_deployment 'blur'

#Rear machine
Syskit.conf.use_deployment 'avalon_back_base_control', :on => 'back'
Syskit.conf.use_deployment 'sonar_distance_estimator', :on => 'back'
#Syskit.conf.use_deployment 'state_estimator', :on => 'back'
Syskit.conf.use_deployment 'orientation_estimator', :on => 'back'
#Syskit.conf.use_deployment 'ikf_orientation_estimator', :on => 'back'
Syskit.conf.use_deployment 'xsens', :on => 'back'
Syskit.conf.use_deployment 'fog', :on => 'back'
Syskit.conf.use_deployment 'echosounder', :on => 'back'
Syskit.conf.use_deployment 'sonar', :on => 'back'
Syskit.conf.use_deployment 'sonar_rear', :on => 'back'
Syskit.conf.use_deployment 'controldev', :on => 'back'
#Syskit.conf.use_deployment 'sysmon', :on => 'back'
Syskit.conf.use_deployment 'modem', :on => 'back'
Syskit.conf.use_deployment 'controlconverter_movement', :on => 'back'
#Syskit.conf.use_deployment 'controlconverter_position', :on => 'back'
Syskit.conf.use_deployment 'asv_detector', :on => 'back'
Syskit.conf.use_deployment 'auv_rel_pos_controller', :on => 'back'
Syskit.conf.use_deployment 'wall_servoing', :on => 'back'
#Syskit.conf.use_deployment 'dual_wall_servoing', :on => 'back'
#Syskit.conf.use_deployment 'pingersearch', :on => 'back'
#Syskit.conf.use_deployment 'audio_reader', :on => 'back'
Syskit.conf.use_deployment 'sonar_feature_estimator', :on => 'back'
Syskit.conf.use_deployment 'taskmon_back', :on => 'back'
Syskit.conf.use_deployment 'localization', :on => 'back'
#Syskit.conf.use_deployment 'battery_management', :on => 'back'
Syskit.conf.use_deployment 'sonar_feature_estimator', :on => 'back'
#Syskit.conf.use_deployment 'orientation_correction', :on => 'back'

Syskit.warn "!!!!!!!   Logging disabled       !!!!"
Syskit.warn "!!!!!!!   Logging disabled       !!!!"
Syskit.conf.disable_logging

Syskit.conf.exclude_from_log '/canbus/Message'
Syskit.conf.exclude_from_log '/canbus/Statistics' 
Syskit.conf.exclude_from_log 'blur' 
Syskit.conf.exclude_from_log 'pipeline_follower' 
Syskit.conf.exclude_from_log 'line_scanner' 
Syskit.conf.exclude_from_log 'front_camera' 


module Avalon 
    class ShellInterface < Roby::Interface::CommandLibrary
        def substate(substate)
            State.lowlevel_substate = substate
        end
        command :substate, "set the current runstate for Avalon as substate pair",
            :substate => "The given substate"
        
	def reset_heading
            Orocos::TaskContext.get('orientation_correction').reset(0.0)
	end
	command :reset_heading, "Reset the orientation to zero -here-"
	
        def reset_depth
            Orocos::TaskContext.get('depth').resetPressure
	end
	command :reset_depth, "Reset the depth to zero -here-"

        def set_position(x,y,z,heading)
            task = Orocos::TaskContext.get 'fake_rel_writer'
            task.x = x
            task.y = y
            task.z = z
            task.heading = heading/180.0*Math::PI
        end
        command :set_position, "Set the position for the fake-writer this is a workaournd method",
            :x => "x-pos",
            :y => "y-pos",
            :z => "z-pos",
            :heading => "heading in degree!"
    end
end

Roby::Interface::Interface.subcommand 'avalon', Avalon::ShellInterface, 'Commands specific to Avalon'
