require "models/profiles/main.rb"
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


module Avalon

    module Profiles
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
                
                com_bus(Dev::Bus::CAN, :as => 'can1').
                    with_conf('default')

                through 'can0' do
                    device(Dev::Hbridge, :as => 'thrusters').
                        can_id(0, 0x700).
                        with_conf("default")

                    device(Dev::Controldev::CANJoystick, :as => 'joystick').
                        period(0.1).
                        can_id(0100,0x7ff)
                    
                    device(Dev::Sensors::DepthReader, :as => 'depth_reader').
                        can_id(0x130,0x7F0).
                        period(0.1).
                        with_conf('default')
                   
                end

            end

            define 'thrusters', Hbridge::Task.dispatch('thrusters',[6, 3, 2, -1, 4, 5]).
                with_arguments('driver_dev' => thrusters_dev)
                    
           
            #New HBridge interface not ported yet
            #Hbridge.system self, 'can0', 'hb_group0', 'thrusters', 0, 1, 2, 3, 4, 5
            use Base::GroundDistanceSrv => altimeter_dev
            use Base::ZProviderSrv => depth_reader_dev 
            
            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask, 'controlled_system' => thrusters_def)
            define 'relative_control_loop', ::Base::ControlLoop.use(AuvRelPosController::Task, base_loop_def)
           
            use Base::OrientationWithZSrv => DephFusion
            use Base::AUVMotionControlledSystemSrv => base_loop_def
            use Base::AUVRelativeMotionControlledSystemSrv => relative_control_loop_def
            use AUVJoystickCommand => AUVJoystickCommand.use(joystick_dev)


           # define('drive_simple', ::Base::ControlLoop).use(AUVJoystickCommand, AvalonControl::MotionControlTask)
          #  define('base_loop_test', ::Base::ControlLoop).use(AvalonControl::FakeWriter, AvalonControl::MotionControlTask)
            
        end
    end
end
    
