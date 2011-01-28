class Odometry::Task
    on :start do |event|
        @odometry_reader = data_reader 'odometry_samples'
    end

    def odometry; @odometry_reader.read end

    poll do
        if sample = odometry
            State.odometry = sample
        end
    end

    on :stop do |_|
        if State.odometry?
            State.delete(:odometry)
        end
    end

end
