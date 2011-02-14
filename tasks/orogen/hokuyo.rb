class Hokuyo::Task
    driver_for 'Dev::Hokuyo' do
        provides Srv::LaserRangeFinder
    end
    provides Srv::HWTimestampInput

    def configure
        super
        orogen_task.port = robot_device.device_id
    end
end

