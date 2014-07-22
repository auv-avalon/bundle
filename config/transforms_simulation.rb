## Transformation definitions for the Roby controller, ROBOT=avalon
load_transformer_conf 'config', 'transforms_common.rb'

dynamic_transform "imu.pose_samples", "body" => "odometry"
