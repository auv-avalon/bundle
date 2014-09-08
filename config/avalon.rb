
if Socket.gethostname == "avalon-rear" or Socket.gethostname == "avalon"
    Syskit.conf.process_server 'front','192.168.128.50', :log_dir => '/mnt/logs/results', :result_dir => '/mnt/logs/results'
elsif
    Syskit.conf.process_server 'front','localhost'
end

#Syskit.conf.app.orocos_start_all_deployments = true

Syskit.conf.use_deployment 'dynamixel', :on => 'front'
Syskit.conf.use_deployment 'camera', :on => 'front'
Syskit.conf.use_deployment 'left_unicap_camera', :on => 'front'
Syskit.conf.use_deployment 'right_unicap_camera', :on => 'front'
Syskit.conf.use_deployment 'buoy_detector', :on => 'front'
Syskit.conf.use_deployment 'taskmon_front', :on => 'front'
Syskit.conf.use_deployment 'sonar_wall_hough', :on => 'front'
Syskit.conf.use_deployment 'lights', :on => 'front'
Syskit.conf.use_deployment 'low_level', :on => 'front'
Syskit.conf.use_deployment 'blur', :on => 'front'

#Rear machine
Syskit.conf.use_deployment 'pipeline_laser_inspection'
Syskit.conf.use_deployment 'pipeline_follower'
Syskit.conf.use_deployment 'avalon_back_base_control'
Syskit.conf.use_deployment 'sonar_distance_estimator'
#Syskit.conf.use_deployment 'state_estimator'
Syskit.conf.use_deployment 'orientation_estimator'
Syskit.conf.use_deployment 'ikf_orientation_estimation'
Syskit.conf.use_deployment 'initialize_orientation_estimation'
Syskit.conf.use_deployment 'pose_estimator'
Syskit.conf.use_deployment 'battery_watcher'
Syskit.conf.use_deployment 'xsens'
Syskit.conf.use_deployment 'fog'
Syskit.conf.use_deployment 'echosounder'
Syskit.conf.use_deployment 'sonar'
Syskit.conf.use_deployment 'sonar_rear'
Syskit.conf.use_deployment 'controldev'
#Syskit.conf.use_deployment 'sysmon'
Syskit.conf.use_deployment 'modem'
##Syskit.conf.use_deployment 'controlconverter_movement'
#Syskit.conf.use_deployment 'controlconverter_position'
#Syskit.conf.use_deployment 'asv_detector'
#Syskit.conf.use_deployment 'auv_rel_pos_controller'
Syskit.conf.use_deployment 'wall_servoing'
Syskit.conf.use_deployment 'structure_servoing'
#Syskit.conf.use_deployment 'dual_wall_servoing'
#Syskit.conf.use_deployment 'pingersearch'
#Syskit.conf.use_deployment 'audio_reader'
Syskit.conf.use_deployment 'sonar_feature_estimator'
Syskit.conf.use_deployment 'taskmon_back'
Syskit.conf.use_deployment 'localization'
#Syskit.conf.use_deployment 'battery_management'
Syskit.conf.use_deployment 'sonar_feature_estimator'
#Syskit.conf.use_deployment 'orientation_correction'

#Syskit.warn "!!!!!!!   Logging disabled       !!!!"
#Syskit.warn "!!!!!!!   Logging disabled       !!!!"
#Syskit.conf.disable_logging

Syskit.conf.exclude_from_log '/canbus/Message'
Syskit.conf.exclude_from_log '/canbus/Statistics' 
Syskit.conf.exclude_from_log 'blur' 
Syskit.conf.exclude_from_log 'pipeline_follower' 
Syskit.conf.exclude_from_log 'line_scanner' 
Syskit.conf.exclude_from_log 'front_camera' 
Syskit.conf.exclude_from_log 'bottom_camera' 

Syskit.conf.exclude_from_log 'low_level_driver' 


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
