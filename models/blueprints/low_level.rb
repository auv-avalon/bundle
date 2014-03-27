require "rock/models/blueprints/pose"
using_task_library "low_level_driver"

module LowLevel
    class Cmp < Syskit::Composition
        add ::LowLevelDriver::LowLevelTask, :as => "ll"
        add ::Base::OrientationWithZSrv, :as => 'z'
        z_child.connect_to ll_child
    end
end
