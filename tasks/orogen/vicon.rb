class Vicon::Task
    driver_for 'Vicon' do
        provides Srv::Pose
    end

    def configure
        super

        dev = robot_device
        orogen_task.host = dev.device_id
    end
end
