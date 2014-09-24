module Dev
    module Sensors 
        device_type "GPS" do
#            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end

class Gps::BaseTask 
    driver_for Dev::Sensors::GPS, as: 'gps'
end
