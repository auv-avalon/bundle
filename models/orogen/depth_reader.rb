require "models/blueprints/avalon"

module Dev
    module Sensors
        device_type "DepthReader" do
            provides Base::ZProviderSrv
            provides Dev::Bus::CAN::ClientInSrv
            provides Dev::Bus::CAN::ClientOutSrv
        end
    end
end


class DepthReader::Task
    driver_for Dev::Sensors::DepthReader, :as => "depth_reader"
    
    on :water_ingress do |event|
        ::State.water_ingress = true
    end

end
    
