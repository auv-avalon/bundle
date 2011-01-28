
class Mars::Task
    driver_for 'Mars', :provides => [Actuators, Position, Orientation, CalibratedIMUSensors, LaserRangeFinder]

    def configure        
        super
        orogen_task.scenario = State.mars_scene
    end

    on :start do |event|
        @orientation_reader = data_reader 'orientation_samples'
        @position_reader = data_reader 'position_samples'
    end


    def orientation
        if sample = @orientation_reader.read
            sample.orientation
        end
    end

    def position
        if sample = @position_reader.read
            sample
        end
    end



    poll do
        if sample = orientation
            State.xsens_imu.orientation = sample
        end
        if sample = position
            State.gps.position = sample
        end
    end
    
end
