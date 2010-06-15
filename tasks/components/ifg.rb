class Ifg::Task
    driver_for 'IfgFOG', :provides => [Orientation]
    def configure
        orogen_task.port = robot_device.device_id
    end
end
