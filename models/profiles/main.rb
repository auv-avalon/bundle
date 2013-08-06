require "models/blueprints/avalon_base"
require "models/blueprints/pose_avalon.rb"

using_task_library 'controldev'
using_task_library 'raw_control_command_converter'
using_task_library 'avalon_control'
using_task_library 'offshore_pipeline_detector'
using_task_library 'auv_rel_pos_controller'
using_task_library 'buoy'

module Avalon
    module Profiles
        profile "AvalonBase" do
            
            define 'base_loop_test', ::Base::ControlLoop.use(AvalonControl::FakeWriter,Base::AUVMotionControlledSystemSrv) 
            define 'base_rel_loop_test', ::Base::ControlLoop.use(AvalonControl::RelFakeWriter, Base::AUVRelativeMotionControlledSystemSrv)
            
            #You need an joystick for this....
            define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, Base::AUVMotionControlledSystemSrv)
            
            
        end
    end
end
    
