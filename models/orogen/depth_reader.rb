require "models/blueprints/avalon_base"

module Dev
    module Sensors
        device_type "DepthReader" do
            provides Base::ZProviderSrv
            provides Dev::Bus::CAN::ClientInSrv
        end
    end
end


class DepthReader::Task
    driver_for Dev::Sensors::DepthReader, :as => "depth_reader"
end
    
class DephFusion < Syskit::Composition
    add ::Base::ZProviderSrv, :as => 'z'
    add ::Base::OrientationSrv, :as => 'ori'
    add DepthReader::DepthAndOrientationFusion, :as => 'task'

    connect z_child => task_child.depth_samples_port
    connect ori_child => task_child.orientation_samples_port

    export task_child.pose_samples_port
    provides ::Base::OrientationWithZSrv, :as => "orientation_with_z"
end
