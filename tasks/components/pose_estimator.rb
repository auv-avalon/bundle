class PoseEstimator::Task
    provides Pose

    orogen_spec.find_output_port('pose_samples').
        triggered_on('odometry_delta_samples')

    def configure
        super
        orogen_task.position_period = 1.0
        orogen_task.odometry_period = 0.01
        orogen_task.scan_period = 0.01
        orogen_task.use_scan_match = true; 
        orogen_task.use_gps = false; 
        orogen_task.slow_max_delay = 2
        orogen_task.fast_max_delay = 0.02

        orogen_task.reject_gps_threshold = 95
        orogen_task.reject_icp_threshold = 95
    end

    on :start do |event|
        if State.initial_position?
            orogen_task.set_position(State.initial_position, 0)
        end
        @reader = data_reader 'pose_samples'
    end

    def pose; @reader.read end

    poll do
        if sample = self.pose
            State.pose = sample
        end
    end

    on :stop do |_|
        if State.pose?
            State.delete(:pose)
        end
    end
end

