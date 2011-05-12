class Sonardetector::Task

    def configure
        super
        sonardetector.enable_beam_threshold = true
        sonardetector.beam_threshold_min = 0.5
        sonardetector.beam_threshold_max = 5
        sonardetector.enable_wall_estimation = true
        sonardetector.min_response_value = 10
    end
end

