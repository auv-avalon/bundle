class Sonardetector::Task

    def configure
        super
        orogen_task.enable_beam_threshold = true
        orogen_task.beam_threshold_min = 1
        orogen_task.beam_threshold_max = 5
        orogen_task.min_response_value = 10
        orogen_task.wall_estimation_start_angle = 2.36
        orogen_task.wall_estimation_end_angle = 3.93
        orogen_task.wall_distance = 3
        orogen_task.fixed_depth = -1
        orogen_task.debug_output = false
    end
end

