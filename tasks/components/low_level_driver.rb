class LowLevelDriver::LowLevelTask
    driver_for 'AvalonLowLevel', :provides => [Depth]

    def configure
	orogen_task.port = robot_device.device_id
    end
end
