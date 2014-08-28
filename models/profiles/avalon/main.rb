CONFIG_HACK = 'default'
require "auv/models/profiles/main"
require "models/blueprints/auv"
require "models/blueprints/pose_auv"
require "models/blueprints/low_level"

using_task_library 'auv_helper'
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
using_task_library 'battery_watcher'


module Avalon
    USE_DAGON_FILTER = true

    module Profiles
        profile "Avalon" do
            tag 'final_orientation', ::Base::OrientationSrv

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

                device(Dev::Sensors::KVH::DSP3000, :as => 'fog').
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
                    device(Dev::Controldev::Joystick, :as => 'joystick', :using => Controldev::Remote).
                        period(0.1).
                        can_id(0x502,0x7FF)

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
                    
                    device(Dev::Sensors::Battery, :as => 'battery').
                        can_id(0x447,0x7FF).
                        period(0.1)
                end

                through 'can1' do
                    device(Dev::Sensors::DepthReader, :as => 'depth_reader_rear').
                        prefer_deployed_tasks('depth_rear').
                        can_id(0x440,0x7FF).
                        period(0.1).
                        with_conf('default')
                end
            end

            # Define thrustersystem 'actuatorss'
            Hbridge.system(self,'can0','actuatorss','thrusters',6, 3, 2, -1, 4, 5)

            if not USE_DAGON_FILTER
                define "raw_orientation", imu_dev
            else
                define "raw_orientation", PoseAuv::DagonOrientationEstimatorCmp.use(
                    'imu' => imu_dev
                )
            end
            

            define 'depth_fusion',   AuvControl::DepthFusionCmp.use(
                Base::ZProviderSrv => depth_reader_dev,
                Base::OrientationSrv => raw_orientation_def,
                Base::GroundDistanceSrv => altimeter_dev
            )

            ###TODO Add if needed some offsets to the orientation or use first define
            define 'orientation', depth_fusion_def 

            #TODO add offset tools?


#            # Define new ControlLoops
#            define 'world_controller', ::Base::ControlLoop.use(
#                'controlled_system' => thrusters_def, 
#                'controller' => AuvCont::WorldPositionCmp
#            )
            
            # Background tasks
            define 'lights', Lights::Lights
            define 'low_level', LowLevel::Cmp.use(
                'z' => depth_fusion_def 
            )

            define 'bottom_camera', VideoStreamerVlc.stream(bottom_camera_dev, 640, 480, 8090)
            define 'front_camera', VideoStreamerVlc.stream(front_camera_dev, 1200, 600, 8080)
            
            define 'motion_model', Localization::DeadReckoning.use(
                'hb' => thrusters_def,
                'ori' => orientation_def
            )
            
            use_profile ::DFKI::Profiles::AUV,
                "final_orientation_with_z" => depth_fusion_def,
                "altimeter" => altimeter_dev,
                "thruster" => thrusters_def,
                #"thruster_feedback" => actuatorss_actuators_dev,
                "thruster_feedback" => thrusters_def,
                "down_looking_camera" => bottom_camera_dev,
                "forward_looking_camera" => front_camera_dev,
                "motion_model" => motion_model_def


        end
    end
end

