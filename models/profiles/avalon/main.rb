CONFIG_HACK = 'default'
require "auv/models/profiles/main"
require "models/blueprints/auv"
require "models/blueprints/pose_auv"
require "models/blueprints/low_level"

using_task_library 'gps'
using_task_library 'auv_helper'
using_task_library 'controldev'
using_task_library 'canbus'
using_task_library 'hbridge'
using_task_library 'sonar_tritech'
using_task_library 'sonar_blueview'
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
using_task_library 'battery_watcher'


module Avalon
    USE_DAGON_FILTER = true

    module Profiles
        profile "Avalon" do
            # load static transforms
            file = Bundles.find_file('config', 'transforms_common.rb')
            transformer do
                load file 
            end

            tag 'final_orientation', ::Base::OrientationSrv

            robot do
                device(Dev::Sensors::Cameras::Network, :as => 'front_camera').
                    with_conf('default',"front_camera").
                    frame('front_camera').
                    prefer_deployed_tasks(/front_camera/).
                    period(0.2)

                device(Dev::Sensors::Cameras::Network, :as => 'bottom_camera').
                    with_conf('default',"bottom_camera").
                    frame('bottom_camera').
                    prefer_deployed_tasks(/bottom_camera/).
                    period(0.2)

                device(Dev::Micron, :as => 'sonar').
                    frame('sonar').
                    prefer_deployed_tasks("sonar").
                    period(0.1)

                device(Dev::Sensors::GPS, :as => 'gps', :using => Gps::GPSDTask).
                       with_conf('default').
                       frame('gps_receiver').
                       period(0.1).
                       use_frames(
                                'map' => 'map_sauce',
                                'gps_utm_zone' => 'world_utm_sauce'
                       )


                device(Dev::Echosounder, :as => 'altimeter').
                    with_conf('default').
                    frame('echosounder').
                    period(0.1)
                
                device(Dev::Sensors::BlueView, :as => 'blueview').
                    with_conf('default').
                    period(0.1)


                device(Dev::Sensors::XsensAHRS, :as => 'imu').
                    frame_transform('imu' => 'imu_nwu').
                    period(0.01)

                device(Dev::Sensors::KVH::DSP3000, :as => 'fog').
                    frame('fog').
                    period(0.01)
                
                com_bus(Dev::Bus::CAN, :as => 'can0').
                    prefer_deployed_tasks("can").
                    with_conf('default','can0')

                com_bus(Dev::Bus::CAN, :as => 'can1').
                    prefer_deployed_tasks("can1").
                    with_conf('default', 'can1')

                through 'can0' do
                    device(Dev::Controldev::Joystick, :as => 'joystick', :using => Controldev::Remote).
                        period(0.1).
                        can_id(0x502,0x7FF)

                    device(Dev::Sensors::DepthReaderAvalon, :as => 'depth_reader').
                        prefer_deployed_tasks('depth').
                        frame('pressure_sensor').
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
                    
                    device(Dev::ASVModem, :as => 'asv_modem', :using => Modemdriver::ModemCanbus).
                        can_id(0x500,0x7FF).
                        period(0.1)
                    
                    
                    device(Dev::Sensors::Modem , :as => 'modem').
                        can_id(0x504,0x7FF).
                        period(0.1)
                    
                    device(Dev::Sensors::Battery, :as => 'battery').
                        can_id(0x447,0x7FF).
                        period(0.1)
                end

                through 'can1' do
                    device(Dev::Sensors::DepthReaderAvalon, :as => 'depth_reader_rear').
                        prefer_deployed_tasks('depth_rear').
                        can_id(0x440,0x7FF).
                        period(0.1).
                        with_conf('default')
                end
            end

            # Define thrustersystem 'actuatorss'
            Hbridge.system(self,'can0','actuatorss','thrusters',6, 3, 2, -1, 4, 5)

#            if not USE_DAGON_FILTER
#                define "raw_orientation", imu_dev
#            else
#                define "raw_orientation", PoseAuv::DagonOrientationEstimatorCmp.use(
#                    'imu' => imu_dev
#                )
#            end
            
            use_profile ::DFKI::Profiles::OrientationEstimation,
                'imu' => imu_dev


            #### Choose between:
            #define "orientation", old_orientation_estimator_def
            define "orientation", ikf_orientation_estimator_def
            #define "orientation",initial_orientation_estimator_def 

            #Test for Constrained based approach, fixind definition to limit searchspace
            use AuvControl::DepthFusionCmp, AuvControl::DepthFusionCmp.use(
                'z' => depth_reader_dev,
                'ori' => orientation_def
            )

            use LowLevel::Cmp, LowLevel::Cmp.use(
                'z' => AuvControl::DepthFusionCmp 
            )
           
            use Localization::DeadReckoning, Localization::DeadReckoning.use(
                'hb' => Hbridge::SensorReader
            )

            use Localization::ParticleDetector, Localization::ParticleDetector.use(
                'hb' => Hbridge::SensorReader,
                'ori' => AuvControl::DepthFusionCmp
            )

            use PoseAuv::PoseEstimatorCmp, PoseAuv::PoseEstimatorCmp.use(
                'ori' => AuvControl::DepthFusionCmp
            )
            
            use Pipeline::Detector, Pipeline::Detector.use(
                'camera' => front_camera_dev 
            )
            
            use Pipeline::Follower, Pipeline::Follower.use(
                'controller' => Pipeline::Detector,
                'controller_local' => Pipeline::Detector,

            )
            
            use PoseAuv::PoseEstimatorBlindCmp, PoseAuv::PoseEstimatorBlindCmp.use(
                'depth' => AuvControl::DepthFusionCmp,
                'ori' => AuvControl::DepthFusionCmp
            )
            
            use Wall::Follower, Wall::Follower.use(
                'controller' => Wall::Detector,
                'controller_local' => Wall::Detector,
            )
            
            use Wall::Detector, Wall::Detector.use(
                'orientation_with_z' => AuvControl::DepthFusionCmp
            )

            ### This is optional an can be removed soon:
            define 'depth_fusion',   AuvControl::DepthFusionCmp.use(
                'z' => depth_reader_dev,
                Base::OrientationSrv => orientation_def
            )
            
            
            define 'motion_model', Localization::DeadReckoning.use(
                'hb' => thrusters_def, 
                'ori' => depth_fusion_def
            )


            define 'depth_fusion',   AuvControl::DepthFusionCmp.use(
                Base::ZProviderSrv => depth_reader_dev,
                Base::OrientationSrv => orientation_def,
                Base::GroundDistanceSrv => altimeter_dev
            )

            ###TODO Add if needed some offsets to the orientation or use first define
            define 'orientation', depth_fusion_def 

            #TODO add offset tools?


            # Background tasks
            define 'lights', Lights::Lights
            define 'low_level', LowLevel::Cmp.use(
                'z' => depth_fusion_def 
            )

            define 'bottom_camera', VideoStreamerVlc.stream(bottom_camera_dev, 640, 480, 5004)
            define 'front_camera', VideoStreamerVlc.stream(front_camera_dev, 1200, 600, 5005)
            define 'blueview', VideoStreamerVlc.stream(blueview_dev, 1200, 600, 5006)
            
            # Load AUV profile
            use_profile ::DFKI::Profiles::PoseEstimation,
                "orientation" => depth_fusion_def,
                "thruster_feedback" => thrusters_def,
                "motion_model" => motion_model_def,
                "depth" => depth_reader_dev,
		'altimeter' => altimeter_dev,
                'gps' => gps_dev


            # Set local frame names
            define 'ikf_orientation_estimator', ikf_orientation_estimator_def.use_frames(
                'imu' => 'imu',
                'fog' => 'fog',
                'body' => 'body'
            ).ori_in_map_child.use_frames(
                'map' => 'map_halle',
                'world' => 'world_orientation'
            )

            initial_orientation_estimator_def.use_frames(
                'body' => 'body',
                'odometry' => 'local_orientation',
                'wall' => 'reference_wall_halle',
                'world' => 'world_orientation',
                'sonar' => 'sonar'
            )

            initial_orientation_estimator_def.estimator_child.use_frames(
                'fog' => 'fog',
                'imu' => 'imu',
                'body' => 'body'
            )
    
            define 'pose_estimator', pose_estimator_def.use_frames(
                'imu' => 'imu',
                'lbl' => 'lbl',
                'pressure_sensor' => 'pressure_sensor',
                'body' => 'body',
                'dvl' => 'dvl',
                'fog' => 'fog'
            )

            pose_estimator_blind_def.use_frames(
                'imu' => 'imu',
                'lbl' => 'lbl',
                'pressure_sensor' => 'pressure_sensor',
                'body' => 'body',
                'dvl' => 'dvl',
                'fog' => 'fog'
            )

            imu_dev.use_frames(
                'imu' => 'imu',
                'world' => 'imu_nwu'
            )
            
#            target_move_new_def.use_frames(
#                 'imu' => 'imu',
#                 'lbl' => 'lbl',
#                 'pressure_sensor' => 'pressure_sensor',
#                 'body' => 'body',
#                 'dvl' => 'dvl',
#                 'fog' => 'fog'
#            )
#
#            simple_move_new_def.use_frames( 
#                'imu' => 'imu',
#              'lbl' => 'lbl',
#                'pressure_sensor' => 'pressure_sensor',
#                 'body' => 'body',
#                'dvl' => 'dvl',
#            'fog' => 'fog'
#            )
#
#            

            # Define dynamic transformation providers
            transformer do
                frames 'dvl', 'body'
                frames 'lbl', 'body'
                dynamic_transform initial_orientation_estimator_def.estimator_child, 'body' => 'local_orientation'
                dynamic_transform pose_estimator_blind_def, 'body' => 'map_halle'
                dynamic_transform pose_estimator_def, 'body' => 'map_halle'
                #dynamic_transform imu_dev, 'imu' => 'imu_nwu'
            end

            ##### Choose between
            define "pose", pose_estimator_blind_def
            define "pose_blind", pose_estimator_def
            define "pose_gps", pose_estimator_gps_def
            #### and
            #define "pose", localization_def
            #define "blind_pose", localization_def
            ### end choose

            ####More Chooses
            #define "ori_with_z", pose_estimator_blind_def
            #define "ori_with_z", pose_estimator_def
            define "ori_with_z", depth_fusion_def 
            ##### end choosing

            define "fix_map", ::Localization::FixMapHack
            
            # Load AUV profile
            use_profile ::DFKI::Profiles::AUV,
                "orientation_with_z" => depth_fusion_def,
                "altimeter" => altimeter_dev,
                "thruster" => thrusters_def,
                "down_looking_camera" => bottom_camera_dev,
                "forward_looking_camera" => front_camera_dev,
                "pose_blind" => pose_estimator_blind_def,
                #"pose" => localization_def,
                "pose" => pose_estimator_def,
                "motion_model" => motion_model_def,
                'map' => localization_def,
                'gps' => gps_dev,
                'pose_gps' => pose_gps_def
              
                #'orientation_to_correct' => orientation_def

        end
    end
end

