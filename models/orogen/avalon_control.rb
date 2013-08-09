require 'models/blueprints/avalon'

class AvalonControl::FakeWriter
    provides Base::AUVMotionControllerSrv, :as => "controller"
end

class AvalonControl::RelFakeWriter
    provides Base::AUVRelativeMotionControllerSrv, :as => "controller"
end

class AvalonControl::MotionControlTask 
    provides Base::AUVMotionControlledSystemSrv, :as => "auv_motion_controlled"
    provides Base::ActuatorControllerSrv, :as => "actuator_controller"
     
end

