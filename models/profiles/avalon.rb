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

#Why i need to use them here, i only need them for my machine not for the system itself
using_task_library 'simulation'
using_task_library 'avalon_simulation'


module Avalon

    STDOUT.puts 
    module Profiles
        profile "AvalonBase" do

            self
        end

        profile "Simulation" do
            use_profile AvalonBase
            robot do
                device(Dev::Simulation::Echosounder, :as => 'altimeter')
                device(Dev::Simulation::Actuator, :as => 'thrusters').
                    use_deployments("avalon_actuators")

                device(Dev::Simulation::IMU, :as => 'imu')
            
                device(Dev::Controldev::Joystick, :as => 'joystick')
            end

                    
            use ::Simulation::Mars => ::AvalonSimulation::Task
            
            use Base::GroundDistanceSrv => altimeter_dev 
            #use Base::ZProviderSrv => Simulated::IMU
#            use Base::ZProviderSrv => Simulated::IMU
#            use Base::OrientationWithZSrv => Simulated::IMU
            use Base::ActuatorControlledSystemSrv => Simulated::Actuator.use_deployments("avalon_actuators") 
           
            define('base_loop_test', ::Base::ControlLoop).use(AvalonControl::FakeWriter, AvalonControl::MotionControlTask)
            
            #You need an joystick for this....
            define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, AvalonControl::MotionControlTask)
            
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
            
            self
        end
    end
end
    
