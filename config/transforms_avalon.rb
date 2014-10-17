## Transformation definitions for the Roby controller, ROBOT=avalon
load_transformer_conf 'config', 'transforms_common.rb'

dynamic_transform "ikf_orientation_estimator.attitude_b_g", "body" => "world_orientation"
dynamic_transform "initial_orientation_estimator.attitude_b_g", "body" => "local_orientation"
dynamic_transform "orientation_in_map.orientation_in_map", "body" => "map_halle"
#dynamic_transform "orientation_estimator.attitude_b_g", "body" => "map_halle"

dynamic_transform "uw_particle_localization.pose_samples", "body" => "map_halle"
dynamic_transform "pose_estimator.pose_samples", "body" => "map_halle"
dynamic_transform "xsens", "imu" => "imu_nwu"
