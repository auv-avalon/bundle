class IgcDriver::IgcImuTask
    driver_for 'IGC', :as => 'device'
    provides Orientation, :as => 'igc', :slave_of => 'device'
    provides Orientation, :as => 'single_fog', :slave_of => 'device'
    provides Orientation, :as => 'fog', :slave_of => 'device'
    provides CompensatedIMUSensors, :slave_of => 'device'
end

