class MotconController::MotconControllerTask
    driver_for 'motcon'
    def configure
        device_id = robot_device.device_id
        orogen_task.port = device_id
    end
end

