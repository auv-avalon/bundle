require "models/blueprints/avalon_base"
require "models/blueprints/pose_avalon.rb"
#require "models/orogen/hbridge/devices"
        
#STDOUT.puts "AvalonC: #{AvalonControl::FakeWriter.ancestors}"

using_task_library 'controldev'
using_task_library 'canbus'
using_task_library 'hbridge'
using_task_library 'sonar_tritech'
using_task_library 'depth_reader'
using_task_library 'raw_control_command_converter'
using_task_library 'avalon_control'
using_task_library 'offshore_pipeline_detector'
using_task_library 'auv_rel_pos_controller'

#Why i need to use them here, i only need them for my machine not for the system itself
using_task_library 'simulation'
using_task_library 'avalon_simulation'


module Avalon

    STDOUT.puts 
    module Profiles
        profile "AvalonBase" do
            
        end

        profile "Simulation" do
            use_profile AvalonBase

           # define_simulated_device("bottom_cam",Dev::Simulation::Camera, :use_deployments => "\"bottom_camera\"", :with_conf  => "\"bottom_cam\"")  #.use_conf('bottom_cam')
            define_simulated_device("front_cam",Dev::Simulation::Camera, :use_deployments => "\"front_camera\"", :with_conf => "\"front_cam\"")#.use_conf('front_cam')
            define_simulated_device("imu",Dev::Simulation::IMU)
            define_simulated_device("thrusters",Dev::Simulation::Actuator, :use_deployments => "\"avalon_actuators\"")

            
            robot do
                device(Dev::Simulation::Echosounder, :as => 'altimeter')
                device(Dev::Controldev::Joystick, :as => 'joystick')
            end
            
            use ::Simulation::Mars => ::AvalonSimulation::Task
            use ::Base::GroundDistanceSrv => altimeter_dev
            use ::Base::OrientationWithZSrv => imu_def 
           
            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask, 'controlled_system' => thrusters_def)
            define 'relative_control_loop', ::Base::ControlLoop.use(AuvRelPosController::Task, base_loop_def)
            
            define 'base_loop_test', ::Base::ControlLoop.use(AvalonControl::FakeWriter,base_loop_def) 
            define 'base_rel_loop_test', ::Base::ControlLoop.use(AvalonControl::RelFakeWriter,relative_control_loop_def)
            
            #You need an joystick for this....
            define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand.use(joystick_dev), base_loop_def)

            define('pipeline_simple', ::Base::ControlLoop).use(PipelineDetector.use(bottom_cam_def), relative_control_loop_def.controller_child.with_conf("pipeline"))

            
            
            self  
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
            use Base::ActuatorControlledSystemSrv => thrusters_def



            define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, AvalonControl::MotionControlTask)
            
            define('base_loop_test', ::Base::ControlLoop).use(AvalonControl::FakeWriter, AvalonControl::MotionControlTask)
            
        end
    end
end
    
