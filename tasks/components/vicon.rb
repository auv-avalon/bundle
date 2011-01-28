class Vicon::Task
    driver_for 'Vicon', :provides => Pose

    def configure
        super

        dev = robot_device
        orogen_task.host = dev.device_id
    end
end
