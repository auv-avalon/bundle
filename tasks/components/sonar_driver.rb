class SonarDriver::SonarDriverMicronTask
    driver_for 'MicronSonar'
    def configure
        super
        orogen_task.attribute('port').write(robot_device.device_id)
    end
end
