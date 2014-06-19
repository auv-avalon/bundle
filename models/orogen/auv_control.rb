require 'models/blueprints/avalon'

class AuvControl::ConstantCommand
    provides ::Base::WorldXYZRollPitchYawControllerSrv, :as => 'world_cmd'
end
