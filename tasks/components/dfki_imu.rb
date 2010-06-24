class DfkiImu::Task
    driver_for 'dfki_imu',  :provides => [Orientation, CompensatedIMUSensors]
    def configure
        super
        # Need to use attribute(:port) as #port is a method on the task context
        orogen_task.attribute(:port).write(robot_device.device_id)
    end

    def orientation
        @orientation_reader ||= orogen_task.port('orientation_samples').reader
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
        if @orientation_reader
            @orientation_reader.disconnect
        end
        if State.dfki_imu.orientation?
            State.dfki_imu.delete(:orientation)
        end
    end
end



