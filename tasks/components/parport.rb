com_bus_type 'HardwareTimestamps', :message_type => '/parport/StateChange', :override_policy => false

class Parport::Task
    driver_for 'Parport', :provides => HardwareTimestamps
    def configure
        super
        bus_name = self.parport_name
        orogen_task.device = robot_device.device_id

        each_attached_device do |dev|
            pin = dev.device_id
            name = dev.name
            Robot.info "#{bus_name}: watching #{name} on #{pin}"
            orogen_task.watch_pin(name, pin)
        end
    end
end

