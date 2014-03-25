require 'models/blueprints/avalon'

module Dev
    module Actuators
        device_type "Lights" do
            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end

class Lights::Lights
    driver_for Dev::Actuators::Lights, as: 'lights'
end
