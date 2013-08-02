require "models/blueprints/avalon_base"
require "models/blueprints/pose_avalon.rb"

using_task_library 'controldev'
using_task_library 'canbus'
using_task_library 'hbridge'
using_task_library 'sonar_tritech'
using_task_library 'depth_reader'
using_task_library 'raw_control_command_converter'
using_task_library 'avalon_control'
using_task_library 'offshore_pipeline_detector'
using_task_library 'auv_rel_pos_controller'
using_task_library 'buoy'

#Why i need to use them here, i only need them for my machine not for the system itself
using_task_library 'simulation'
using_task_library 'avalon_simulation'


module Avalon

    STDOUT.puts 
    module Profiles
        profile "AvalonBase" do
            
            define 'base_loop_test', ::Base::ControlLoop.use(AvalonControl::FakeWriter,Base::AUVMotionControlledSystemSrv) 
            define 'base_rel_loop_test', ::Base::ControlLoop.use(AvalonControl::RelFakeWriter, Base::AUVRelativeMotionControlledSystemSrv)
            
            #You need an joystick for this....
            define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, Base::AUVMotionControlledSystemSrv)
            
            
        end

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

            define 'pipeline', ::Base::ControlLoop.use(PipelineDetector.use(bottom_cam_def), 'controlled_system' => Base::ControlLoop.use(Base::AUVMotionControlledSystemSrv, AuvRelPosController::Task.with_conf('default','pipeline')))
            define 'buoy', ::Base::ControlLoop.use(BuoyDetector.use(front_cam_def), Base::AUVRelativeMotionControlledSystemSrv) 
            

        end

        profile "Avalon" do
            use_profile AvalonBase

            robot do
                
                device(Dev::Echosounder, :as => 'altimeter').
                    period(0.1)
                #TODO add subspecs

                device(Dev::Sensors::XsensAHRS, :as => 'imu').
                    period(0.01)
                device(Dev::Sensors::FOG, :as => 'fog').
                    period(0.01)

                com_bus(Dev::Bus::CAN, :as => 'can0').
                    with_conf('default','can0')

                through 'can0' do
                    device(Dev::Controldev::CANJoystick, :as => 'joystick').
                        period(0.1).
                        can_id(0100,0x7ff)
                    
                    device(Dev::Sensors::DepthReader, :as => 'depth_reader').
                        can_id(0x130,0x7F0).
                        period(0.1)
                end

            end
            
            Hbridge.system self, 'can0', 'hb_group0', 'thrusters', 0, 1, 2, 3, 4, 5
            
            use Base::GroundDistanceSrv => altimeter_dev
            use Base::ZProviderSrv => depth_reader_dev 
            
            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask, 'controlled_system' => thrusters_def)
            define 'relative_control_loop', ::Base::ControlLoop.use(AuvRelPosController::Task, base_loop_def)
            
            use Base::AUVMotionControlledSystemSrv => base_loop_def
            use Base::AUVRelativeMotionControlledSystemSrv => relative_control_loop_def
            use AUVJoystickCommand => AUVJoystickCommand.use(joystick_dev)


           # define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, AvalonControl::MotionControlTask)
          #  define('base_loop_test', ::Base::ControlLoop).use(AvalonControl::FakeWriter, AvalonControl::MotionControlTask)
            
        end
    end
end
    
