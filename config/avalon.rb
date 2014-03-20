#Front Machine
Syskit.conf.process_server 'front','192.168.128.50' #, :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'
#Syskit.conf.process_server 'front','localhost' #, :log_dir => '/mnt/logs/log', :result_dir => '/mnt/logs/results'

Syskit.conf.use_deployment 'dynamixel', :on => "front"
Syskit.conf.use_deployment 'front_camera', :on => "front"
Syskit.conf.use_deployment 'bottom_camera', :on => "front"
Syskit.conf.use_deployment 'left_unicap_camera', :on => "front"
Syskit.conf.use_deployment 'right_unicap_camera', :on => "front"
Syskit.conf.use_deployment 'buoy_detector', :on => "front"
Syskit.conf.use_deployment 'pipeline_follower', :on => "front"
Syskit.conf.use_deployment 'taskmon_front', :on => "front"
Syskit.conf.use_deployment 'sonar_wall_hough', :on => "front"
Syskit.conf.use_deployment 'avalon_gps', :on => "front"

#Rear machine
Syskit.conf.use_deployment 'avalon_back_base_control'
Syskit.conf.use_deployment 'sonar_distance_estimator'
#Syskit.conf.use_deployment 'state_estimator'
Syskit.conf.use_deployment 'orientation_estimator'
#Syskit.conf.use_deployment 'ikf_orientation_estimator'
Syskit.conf.use_deployment 'xsens'
Syskit.conf.use_deployment 'fog'
Syskit.conf.use_deployment 'echosounder'
Syskit.conf.use_deployment 'sonar'
Syskit.conf.use_deployment 'sonar_rear'
Syskit.conf.use_deployment 'controldev'
#Syskit.conf.use_deployment 'sysmon'
Syskit.conf.use_deployment 'modem'
Syskit.conf.use_deployment 'controlconverter_movement'
#Syskit.conf.use_deployment 'controlconverter_position'
Syskit.conf.use_deployment 'asv_detector'
Syskit.conf.use_deployment 'auv_rel_pos_controller'
Syskit.conf.use_deployment 'wall_servoing'
#Syskit.conf.use_deployment 'dual_wall_servoing'
#Syskit.conf.use_deployment 'pingersearch'
#Syskit.conf.use_deployment 'audio_reader'
Syskit.conf.use_deployment 'sonar_feature_estimator'
Syskit.conf.use_deployment 'taskmon_back'
Syskit.conf.use_deployment 'uw_particle_localization'
Syskit.conf.use_deployment 'auv_waypoint_navigator'
#Syskit.conf.use_deployment 'battery_management'
Syskit.conf.use_deployment 'sonar_feature_estimator'

Syskit.conf.disable_logging
