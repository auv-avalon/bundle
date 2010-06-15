class LowLevelDriver::LowLevelTask
    driver_for 'AvalonLowLevel', :provides => [Depth]

    def configure
        # Need to use attribute(:port) as #port is a method on the task context
	orogen_task.attribute(:port).write(robot_device.device_id)
    end
end
