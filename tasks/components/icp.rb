class Icp::Task
    find_output_port('pose_samples').
        triggered_once_per_update
    worstcase_processing_time 1

    def configure
        super
        orogen_task.environment_debug_path = "/tmp/icp_env"
        orogen_task.environment_path = State.environment_map_path
        orogen_task.scan_period = 0.020
        orogen_task.max_delay = 5
        orogen_task.max_iterations = 20
        orogen_task.measurement_density = 0.01 
        orogen_task.model_density = 1.0 
        orogen_task.overlap = 0.95
        orogen_task.state_estimation_period = 0.01
        orogen_task.odometry_period = 0.01
        orogen_task.lines_per_pointcloud = 15
        orogen_task.min_line_advance = 10 
        orogen_task.min_line_dist = 0.01 
        orogen_task.min_line_angle = 0.05
    end
end

