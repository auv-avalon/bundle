class AcousticModem::AcousticModemTask
    driver_for 'TritechModem'

    def configure
    	super
        orogen_task.property('port').write(robot_device.device_id)
    end
end
