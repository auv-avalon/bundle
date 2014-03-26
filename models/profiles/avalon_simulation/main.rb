require "models/profiles/main.rb"
require "models/blueprints/avalon"
require "models/blueprints/pose_avalon"

using_task_library 'simulation'
using_task_library 'avalon_simulation'

#class Dev::Simulation::Mars::SimulatedDevice
#    add Simulation::AuvController.with_conf('default'), :as => "avalon"
#end

module Avalon

    module Profiles
        profile "Simulation" do
            use_profile AvalonBase

            define_simulated_device("bottom_cam", Dev::Simulation::Mars::Camera) do |dev|
                dev.prefer_deployed_tasks("bottom_camera").with_conf("default","bottom_cam")
            end
            define_simulated_device("front_cam", Dev::Simulation::Mars::Camera) do |dev|
                dev.prefer_deployed_tasks("front_camera").with_conf("default","front_cam")
            end
#            define_simulated_device("buoyancy", Dev::Simulation::Mars::AuvController) do |dev|
#                dev.with_conf("default")
#            end
            define_simulated_device("imu", Dev::Simulation::Mars::IMU)
            define_simulated_device("altimeter", Dev::Simulation::Mars::Altimeter)
            define_simulated_device("sonar", Dev::Simulation::Mars::Sonar) do |dev|
                dev.prefer_deployed_tasks("sonar")
            end

            define_simulated_device("thrusters",Dev::Simulation::Mars::AuvMotion) do |dev|
                dev.prefer_deployed_tasks(/avalon_actuators/)
            end

            robot do
                device(Dev::Controldev::Joystick, :as => 'joystick')
            end

            #use ::Simulation::Mars => ::AvalonSimulation::Task
            use ::Base::GroundDistanceSrv => altimeter_def
            use ::Base::OrientationWithZSrv => imu_def
            use ::Base::OrientationSrv => imu_def

            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask.with_conf('default','simulation'), 'controlled_system' => thrusters_def)
            define 'relative_control_loop', ::Base::ControlLoop.use('controller' => AuvRelPosController::Task, 'controlled_system' => base_loop_def)
            define 'position_control_loop', ::Base::ControlLoop.use('controller' =>  AvalonControl::PositionControlTask, 'controlled_system' => base_loop_def)

            use Base::AUVMotionControlledSystemSrv => base_loop_def
            use Base::AUVRelativeMotionControlledSystemSrv => relative_control_loop_def
            use AvalonControl::JoystickCommandCmp => AvalonControl::JoystickCommandCmp.use(joystick_dev)

            use Buoy::DetectorCmp => Buoy::DetectorCmp.use(front_cam_def)

            use Pipeline::Detector => Pipeline::Detector.use(bottom_cam_def,OffshorePipelineDetector::Task.with_conf('default','simulation'))
            #TODO Workaround move to the base profile
            define 'pipeline_detector', Pipeline::Detector

            #Warning setting of with_conf does not work on the def (composition)
            #use Wall::Detector => Wall::Detector.use(sonar_dev.with_conf('wall_servoing_right'), "sonar" => sonar_def)
            use Wall::Detector => Wall::Detector.use(sonar_def)

            define 'sim', ::Simulation::Mars

            use ::Base::PoseSrv => Localization::ParticleDetector.use(imu_def, sonar_def,thrusters_def)
            define 'localization_detector', Localization::ParticleDetector
            
            use ::AvalonControl::SimplePosMove => ::AvalonControl::SimplePosMove.use(position_control_loop_def, localization_detector_def, imu_def)
            define 'target_move', ::AvalonControl::SimplePosMove
            
            define 'wall_right', Wall::Follower.use(WallServoing::SingleSonarServoing.with_conf('default','wall_right'), 'controlled_system' => Base::ControlLoop.use('controlled_system' => Base::AUVMotionControlledSystemSrv, 'controller' => AuvRelPosController::Task.with_conf('default','relative_heading')))


        end
    end
end

