require 'models/blueprints/auv_control'

class AuvControl::ConstantCommandTask
    provides Base::WorldXYZRollPitchYawControllerSrv, :as => "world_cmd"
end
