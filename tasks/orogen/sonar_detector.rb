class Sonardetector::Task

    def configure
        super
        orogen_task.enable_beam_threshold = true
        orogen_task.beam_threshold_min = 0.5
        orogen_task.beam_threshold_max = 5
        orogen_task.enable_wall_estimation = true
        orogen_task.min_response_value = 10
    end
end

