require "models/profiles/main.rb"
require "models/blueprints/avalon_base"
require "models/blueprints/pose_avalon.rb"

using_task_library 'simulation'
using_task_library 'avalon_simulation'


module Avalon

    module Profiles
        profile "Simulation" do
            use_profile AvalonBase

            define_simulated_device("bottom_cam", Dev::Simulation::Mars::Camera) do |dev|
                dev.use_deployments(/bottom_camera/).with_conf("default","bottom_cam")
            end
            define_simulated_device("front_cam", Dev::Simulation::Mars::Camera) do |dev|
                dev.use_deployments(/front_camera/).with_conf("default","front_cam")
            end
            define_simulated_device("imu", Dev::Simulation::Mars::IMU)
            define_simulated_device("thrusters",Dev::Simulation::Mars::Actuators) do |dev|
                dev.use_deployments(/avalon_actuators/)
            end
            
            robot do
                device(Dev::Simulation::Echosounder, :as => 'altimeter')
                device(Dev::Controldev::Joystick, :as => 'joystick')
            end
            
            use ::Simulation::Mars => ::AvalonSimulation::Task
            use ::Base::GroundDistanceSrv => altimeter_dev
            use ::Base::OrientationWithZSrv => imu_def 
           
            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask.with_conf('default','simulation'), 'controlled_system' => thrusters_def)
            define 'relative_control_loop', ::Base::ControlLoop.use(AuvRelPosController::Task, base_loop_def)

            use Base::AUVMotionControlledSystemSrv => base_loop_def
            use Base::AUVRelativeMotionControlledSystemSrv => relative_control_loop_def
            use AUVJoystickCommand => AUVJoystickCommand.use(joystick_dev)

            use BuoyDetector => BuoyDetector.use(front_cam_def) 
            use PipelineDetector => PipelineDetector.use(bottom_cam_def)

            #define 'pipeline', PipelineDetector.use(::Base::ControlLoop.use('controlled_system' => Base::ControlLoop.use(Base::AUVMotionControlledSystemSrv, AuvRelPosController::Task.with_conf('default','pipeline'))))
            define 'pipeline', ::Base::ControlLoop.use(PipelineDetector.use(bottom_cam_def).with_arguments(:speed_x => 1), 'controlled_system' => Base::ControlLoop.use(Base::AUVMotionControlledSystemSrv, AuvRelPosController::Task.with_conf('default','pipeline')))
            define 'buoy', ::Base::ControlLoop.use(BuoyDetector.use(front_cam_def), Base::AUVRelativeMotionControlledSystemSrv) 
            

        end

end
    
