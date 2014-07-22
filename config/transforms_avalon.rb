## Transformation definitions for the Roby controller, ROBOT=avalon
load_transformer_conf 'config', 'transforms_common.rb'

dynamic_transform "orientation_estimator.attitude_b_g", "body" => "odometry"
