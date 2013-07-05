class MainPlanner
    describe("deploys all declared devices").
        optional_arg('excludes', 'list of device names that should not be deployed')
    method(:data_acquisition) do
        root = DataAcquisition.new

        excludes = (arguments[:excludes] || [])
        if excludes.respond_to?(:to_str)
            excludes = [excludes]
        end
        excludes = excludes.to_set

        Roby.app.orocos_engine.robot.devices.each do |device_name, device|
            if !device.kind_of?(Orocos::RobyPlugin::SlaveDeviceInstance) && !excludes.include?(device_name)
                root.depends_on(Orocos::RobyPlugin.require_task(device_name))
            end
        end
        root
    end
end

