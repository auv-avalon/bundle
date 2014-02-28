require "models/profiles/main"
require "models/blueprints/avalon"
require "models/blueprints/pose_avalon"

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
using_task_library 'camera_prosilica'
using_task_library 'sysmon'


module Avalon

    module Profiles
        profile "Avalon" do
            use_profile AvalonBase

            robot do
                device(Dev::Sensors::Cameras::Network, :as => 'front_camera').
                    with_conf('default',"front_camera").
                    prefer_deployed_tasks(/front_camera/).
                    period(0.2)

                device(Dev::Sensors::Cameras::Network, :as => 'bottom_camera').
                    with_conf('default',"bottom_camera").
                    prefer_deployed_tasks(/bottom_camera/).
                    period(0.2)

                device(Dev::Micron, :as => 'sonar').
                    with_conf('default','maritime_hall').
                    prefer_deployed_tasks("sonar").
                    period(0.1)

                device(Dev::Echosounder, :as => 'altimeter').
                    with_conf('default').
                    period(0.1)

                device(Dev::Sensors::XsensAHRS, :as => 'imu').
                    period(0.01)

                device(Dev::Sensors::FOG, :as => 'fog').
                    period(0.01)
                
#                device(Dev::Micron, :as => 'sonar').
#                    use_deployments("sonar").
#                    with_conf('default','testbed').
#                    period(0.01)

                com_bus(Dev::Bus::CAN, :as => 'can0').
                    prefer_deployed_tasks("can").
                    with_conf('default','can0')

#                com_bus(Dev::Bus::CAN, :as => 'can1').
#                    prefer_deployed_tasks("can1").
#                    with_conf('default', 'can0')

                through 'can0' do
                    device(Dev::Controldev::CANJoystick, :as => 'joystick').
                        period(0.1).
                        can_id(0x502,0x7FF)

                    device(Dev::Sensors::DepthReader, :as => 'depth_reader').
                        prefer_deployed_tasks('depth').
                        can_id(0x440,0x7F0).
                        period(0.1).
                        with_conf('default')

#                    device(Dev::ExperimentMarkers, :as => 'marker').
#                        can_id(0x1C0,0x7FF).
#                        period(0.1)

                    device(Dev::SystemStatus, :as => 'sysmon').
                        can_id(0x541,0x7FF).
                        period(0.1)
                end
                

            end

            Hbridge.system(self,'can0','actuatorss','thrusterss',6, 3, 2, -1, 4, 5)
#            define 'thrusters', Hbridge::Task.dispatch('thrusters',[6, 3, 2, -1, 4, 5]).
#                with_arguments('driver_dev' => thrusters_dev)


            #New HBridge interface not ported yet
            #Hbridge.system self, 'can0', 'hb_group0', 'thrusters', 0, 1, 2, 3, 4, 5
            use Base::GroundDistanceSrv => altimeter_dev
            use Base::ZProviderSrv => depth_reader_dev

            define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask, 'controlled_system' => thrusterss_def)
            define 'relative_control_loop', ::Base::ControlLoop.use('controller' => AuvRelPosController::Task, 'controlled_system' => base_loop_def)
            #define 'base_loop', Base::ControlLoop.use('controller' => AvalonControl::MotionControlTask, 'controlled_system' => thrusters_def)
            #define 'relative_control_loop', ::Base::ControlLoop.use('controller' => AuvRelPosController::Task, 'controlled_system' => base_loop_def)

            #Use Dagons Filter, comment out for XSens as Orientation Provider
            use AvalonControl::DephFusionCmp => AvalonControl::DephFusionCmp.use(PoseAvalon::DagonOrientationEstimator)

            use Base::OrientationWithZSrv => AvalonControl::DephFusionCmp

            use Base::AUVMotionControlledSystemSrv => base_loop_def
            use Base::AUVRelativeMotionControlledSystemSrv => relative_control_loop_def
            use AvalonControl::JoystickCommandCmp => AvalonControl::JoystickCommandCmp.use(joystick_dev)

            use Buoy::DetectorCmp => Buoy::DetectorCmp.use(front_camera_dev)
            use Pipeline::Detector => Pipeline::Detector.use(bottom_camera_dev)
            
            use Wall::Detector => Wall::Detector.use(sonar_dev.with_conf('wall_servoing_right'))

#            actuators = actuators_dev = robot.find_device("#{actuatorss}_actuators.#{thrusterss}")
            use  Localization::ParticleDetector => Localization::ParticleDetector.use(AvalonControl::DephFusionCmp.use(PoseAvalon::DagonOrientationEstimator,depth_reader_dev), sonar_dev)
#            use  Localization::ParticleDetector => Localization::ParticleDetector.use(AvalonControl::DephFusionCmp.use(PoseAvalon::DagonOrientationEstimator,depth_reader_dev), sonar_dev,thrusters_def)
            define 'localization_detector', Localization::ParticleDetector
            define 'target_move', ::AvalonControl::SimplePosMove.use(relative_control_loop_def,localization_detector_def)

            define 'depth_fusion', AvalonControl::DephFusionCmp
            
            define 'joystick_control', AvalonControl::JoystickCommandCmp
            
            define 'buoy_detector', Buoy::DetectorCmp
            define 'pipeline_detector', Pipeline::Detector

        end
    end
end

