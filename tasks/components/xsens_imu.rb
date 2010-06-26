class XsensImu::Task
    driver_for 'xsens_imu', :provides => [Orientation, CalibratedIMUSensors]

    def configure
        super
        orogen_task.port = robot_device.device_id
    end

    def orientation
        @orientation_reader ||= orogen_task.port('orientation_samples').reader
        if sample = @orientation_reader.read
            sample.orientation
        end
    end

    poll do
        if sample = orientation
            State.xsens_imu.orientation = sample
        end
    end

    on :stop do |_|
        if State.xsens_imu.orientation?
            State.xsens_imu.delete(:orientation)
        end
    end
end

