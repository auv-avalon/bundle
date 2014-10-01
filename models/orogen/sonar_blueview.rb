module Dev
    module Sensors 
        device_type "BlueView" do 
                provides Base::ImageProviderSrv
        end
    end
end

class SonarBlueview::Task
    driver_for Dev::Sensors::BlueView, :as => 'sonar' 
end

