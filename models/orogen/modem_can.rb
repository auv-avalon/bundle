module Dev
    module Sensors 
        device_type "Modem" do
            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end

class ModemCan::Task
    driver_for Dev::Sensors::Modem, as: 'modem'
    worstcase_processing_time 1.0

end
