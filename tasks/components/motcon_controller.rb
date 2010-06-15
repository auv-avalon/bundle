class MotconController::MotconControllerTask
    driver_for 'motcon'
    def configure
        device_id = robot_device.device_id
        # Need to use attribute(:port) as #port is a method on the task context
        orogen_task.attribute(:port).write(device_id)
    end
end

