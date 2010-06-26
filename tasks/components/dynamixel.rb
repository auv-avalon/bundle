class Dynamixel::Task
    driver_for "dynamixel"

    def configure
    	super
	orogen_task.port = robot_device.device_id
    end
end

