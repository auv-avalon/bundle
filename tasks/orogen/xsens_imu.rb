class XsensImu::Task
    driver_for 'Dev::XsensImu' do
        provides Srv::Orientation
        provides Srv::CalibratedIMUSensors
    end
end

