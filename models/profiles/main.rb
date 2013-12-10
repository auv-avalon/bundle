require "models/blueprints/avalon"
require "models/blueprints/pose_avalon"
require "models/blueprints/wall"
require "models/blueprints/buoy"
require "models/blueprints/pipeline"
require "models/blueprints/avalon_control"
require "models/blueprints/localization"

using_task_library 'controldev'
using_task_library 'raw_control_command_converter'
using_task_library 'avalon_control'
#using_task_library 'offshore_pipeline_detector'
using_task_library 'auv_rel_pos_controller'
#using_task_library 'buoy'

module Avalon
    module Profiles
        profile "AvalonBase" do


            define 'base_loop_test', ::Base::ControlLoop.use(AvalonControl::FakeWriter,Base::AUVMotionControlledSystemSrv)
            define 'base_rel_loop_test', ::Base::ControlLoop.use(AvalonControl::RelFakeWriter, Base::AUVRelativeMotionControlledSystemSrv)

            #You need an joystick for this....
            define('drive_simple', ::Base::ControlLoop).use(AvalonControl::JoystickCommandCmp, Base::AUVMotionControlledSystemSrv)

            define 'pipeline', Pipeline::Follower.use('controlled_system' => Base::ControlLoop.use('controlled_system' => Base::AUVMotionControlledSystemSrv, 'controller' => AuvRelPosController::Task.with_conf('default','relative_heading')))
            define 'wall_right', Wall::Follower.use(WallServoing::SingleSonarServoing.with_conf('default','wall_right'), 'controlled_system' => Base::ControlLoop.use('controlled_system' => Base::AUVMotionControlledSystemSrv, 'controller' => AuvRelPosController::Task.with_conf('default','relative_heading')))
            define 'buoy', Buoy::FollowerCmp.use(Base::AUVRelativeMotionControlledSystemSrv)
            define 'simple_move', ::AvalonControl::SimpleMove.use(Base::AUVRelativeMotionControlledSystemSrv)
            define 'target_move', Localization::Follower.use('controlled_system' => Base::ControlLoop.use('controlled_system' => Base::AUVMotionControlledSystemSrv, 'controller' => AuvRelPosController::Task.with_conf('default')))

            define 'buoy_detector', Buoy::DetectorCmp
            define 'pipeline_detector', Pipeline::Detector
            define 'wall_detector_right', Wall::Detector


        end
    end
end


