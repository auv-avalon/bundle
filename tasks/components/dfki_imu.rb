class DfkiImu::Task
    driver_for 'DfkiImu',  :provides => [Orientation, CompensatedIMUSensors]
    def configure
        super
        orogen_task.port = robot_device.device_id
    end

    on :start do |event|
        @orientation_reader = data_reader 'orientation_samples'
    end

    def orientation
        if sample = @orientation_reader.read
            sample.orientation
        end
    end

    poll do
        if sample = orientation
            State.dfki_imu.orientation = sample
        end
    end

    on :stop do |_|
        if State.dfki_imu.orientation?
            State.dfki_imu.delete(:orientation)
        end
    end
end



