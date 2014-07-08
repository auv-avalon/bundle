require "models/profiles/main"
require "models/blueprints/avalon"
require "models/blueprints/pose_avalon"
require "models/blueprints/low_level"

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
using_task_library 'lights'
using_task_library 'modem_can'
using_task_library 'video_streamer_vlc'
using_task_library 'auv_control'


module Avalon
    USE_ORIENTATION_FILTER = true

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

                com_bus(Dev::Bus::CAN, :as => 'can1').
                    prefer_deployed_tasks("can1").
                    with_conf('default', 'can1')

                through 'can0' do
            #        device(Dev::Controldev::Raw, :as => 'joystick', :using => Controldev::Remote).
            #            period(0.1).
            #            can_id(0x502,0x7FF)

                    device(Dev::Sensors::DepthReader, :as => 'depth_reader').
                        prefer_deployed_tasks('depth').
                        can_id(0x440,0x7FF).
                        period(0.1).
                        with_conf('default')

                    device(Dev::Actuators::Lights, :as => 'lights').
                        can_id(0x503,0x7FF)

#                    device(Dev::ExperimentMarkers, :as => 'marker').
#                        can_id(0x1C0,0x7FF).
#                        period(0.1)

                    device(Dev::SystemStatus, :as => 'sysmon').
                        can_id(0x541,0x7FF).
                        period(0.1)
                    
                    device(Dev::Sensors::Modem , :as => 'modem').
                        can_id(0x504,0x7FF).
                        period(0.1)
                end

                through 'can1' do
                    device(Dev::Sensors::DepthReader, :as => 'depth_reader_rear').
                        prefer_deployed_tasks('depth_rear').
                        can_id(0x440,0x7F0).
                        period(0.1).
                        with_conf('default')
                end
            end

            # Define thrustersystem 'actuatorss'
            Hbridge.system(self,'can0','actuatorss','thrusters',6, 3, 2, -1, 4, 5)

            # Use basic sensor-information-providers
            #use Base::ZProviderSrv => depth_reader_dev
            #use Base::GroundDistanceSrv => altimeter_dev

            ############## Orientation Provider and Depth fusion also orientation corretion if needed #####

            if not USE_ORIENTATION_FILTER
                define "raw_orientation", imu_dev
            else
                define "raw_orientation", PoseAvalon::OrientationEstimatorCmp.use(
                    'imu' => imu_dev
                )
            end

            define 'depth_fusion',   AvalonControl::DepthFusionCmp.use(
                Base::ZProviderSrv => depth_reader_dev,
                Base::OrientationSrv => raw_orientation_def,
                Base::GroundDistanceSrv => altimeter_dev
            )


            ###TODO Add if needed some offsets to the orientation or use first define
            define 'orientation', raw_orientation_def

            #TODO add offset tools?



            #TODO bug does not work:
            #use Base::OrientationWithZSrv => depth_fusion_def

            ############### DEPRICATED ##########################
            # Define old base ControlLoops
            define 'base_loop', Base::ControlLoop.use(
                Base::OrientationWithZSrv => depth_fusion_def,
                'dist' => altimeter_dev,
                'controller' => AvalonControl::MotionControlTask,
                'controlled_system' => thrusters_def
            )
            define 'relative_control_loop', ::Base::ControlLoop.use(
                'controller' => AuvRelPosController::Task, 
                'controlled_system' => base_loop_def
            )
            define 'relative_heading_loop', ::Base::ControlLoop.use(
                'controlled_system' => base_loop_def, 
                'controller' => AuvRelPosController::Task.with_conf('default','relative_heading')
            )
            #TODO Bug
            #use Base::JointsStatusSrv => thrusters_def
            
            define 'bottom_camera_def', VideoStreamerVlc.stream(bottom_camera_dev, 640, 480, 8090)
            define 'front_camera_def', VideoStreamerVlc.stream(front_camera_dev, 1200, 600, 8080)

            #use Wall::Detector => Wall::Detector.use(sonar_dev.with_conf('wall_servoing_right'))


            ############### /DEPRICATED #########################


            # Define new ControlLoops
            define 'world_controller', ::Base::ControlLoop.use(
                'controlled_system' =>thrusters_def,
                'controller' => AuvCont::WorldPositionCmp 
            )
            
            # Background tasks
            define 'lights', Lights::Lights
            define 'low_level', LowLevel::Cmp


            # Localization
            
            #BUG or intended?: i need the deadRecogning only to definne to resolve hbridges?! for the localization?
            define 'motion_model', Localization::DeadReckoning.use(
                'hb' => thrusters_def
            )

            define 'hough_detector', Localization::HoughDetector.use(
                Base::OrientationSrv => orientation_def 
            )

            define 'localization', Localization::ParticleDetector.use(
                motion_model_def,
                Base::OrientationWithZSrv => depth_fusion_def, 
                'hough' => hough_detector_def,
                'hb' => thrusters_def,
            )

            ############### DEPRICATED ##########################
            # Define HighLevelControllers
            define 'position_control_loop', ::Base::ControlLoop.use(
                'controller' =>  AvalonControl::PositionControlTask, 
                'controlled_system' => base_loop_def,
                'pose' => localization_def
            )
            ############### /DEPRICATED #########################


            # Basic Movements
            define 'target_move', ::AvalonControl::SimplePosMove.use(
                'controlled_system' => base_loop_def,
                'pose' => localization_def,
                'controller' => AvalonControl::RelFakeWriter
            )

            define 'target_move_new', ::AuvCont::PositionMove.use(
                Base::PoseSrv => localization_def, 
                'controlled_system' => world_controller_def,
                'controller' => AuvControl::ConstantCommand
                #Base::GroundDistanceSrv => altimeter_dev, 
                #Base::ZProviderSrv => depth_reader_dev
            )

            define 'simple_pos_move', ::AvalonControl::SimplePosMove.use(
                'controlled_system' => position_control_loop_def, 
                'pose' => localization_def, 
            )

            # HighLevelDetectors
            define 'buoy_detector', Buoy::DetectorCmp.use(
                'camera' => front_camera_dev
            )
            define 'pipeline_detector', Pipeline::Detector.use(
                'camera' => bottom_camera_dev
            )
            define 'line_scanner', Pipeline::LineScanner.use(
               bottom_camera_dev, 
                LineScanner::Task.with_conf('default')
            )
            define 'wall_detector_right', Wall::Detector

            # HighLevelController
            define 'trajectory_move', ::AvalonControl::TrajectoryMove.use(
                position_control_loop_def, 
                localization_def, 
                depth_fusion_def, 
            )
            define 'wall_right', Wall::Follower.use(
                'controlled_system' => relative_heading_loop_def
            )
            
            # external control
#            define 'joystick_control', AvalonControl::JoystickCommandCmp.use(
#                joystick_dev
#            )
        end 
    end
end

