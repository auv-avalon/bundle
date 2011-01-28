class Hokuyo::Task
    driver_for 'Hokuyo', :provides => LaserRangeFinder

    def configure
        super
        orogen_task.port = robot_device.device_id
    end
end

