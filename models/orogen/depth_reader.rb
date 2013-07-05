require "models/blueprints/avalon_base"

module Dev
    module Sensors
        device_type "DepthReader" do
            provides Avalon::ZProviderSrv
            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end


class DepthReader::Task
    driver_for Dev::Sensors::DepthReader, :as => "depth_reader"
end
