class Ifg::Task
    driver_for 'IfgFOG', :provides => [Orientation]
    def configure
        super
        # Need to use attribute(:port) as #port is a method on the task context
        orogen_task.attribute(:port).write(robot_device.device_id)
    end
end
