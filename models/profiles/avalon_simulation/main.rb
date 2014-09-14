CONFIG_HACK = 'simulation'
require "auv/models/profiles/main"
require "models/blueprints/auv"
require "models/blueprints/pose_auv"

using_task_library 'controldev'
using_task_library 'simulation'
using_task_library 'avalon_simulation'

#class Dev::Simulation::Mars::SimulatedDevice
#    add Simulation::AuvController.with_conf('default'), :as => "avalon"
#end

module Avalon

    module Profiles
        profile "Simulation" do
            # load static transforms
            transformer do
                load 'config', 'transforms_common.rb'
            end

            tag 'final_orientation', ::Base::OrientationSrv

            define_simulated_device("bottom_camera", Dev::Simulation::Mars::Camera) do |dev|
                dev.prefer_deployed_tasks("bottom_camera").with_conf("default","bottom_cam")
            end
            define_simulated_device("front_camera", Dev::Simulation::Mars::Camera) do |dev|
                dev.prefer_deployed_tasks("front_camera").with_conf("default","front_cam")
            end
            
            define_simulated_device("imu", Dev::Simulation::Mars::IMU)
            define_simulated_device("altimeter", Dev::Simulation::Mars::Altimeter)
            define_simulated_device("sonar", Dev::Simulation::Mars::Sonar) do |dev|
                dev.prefer_deployed_tasks("sonar")
            end

            define_simulated_device("thrusters",Dev::Simulation::Mars::AuvMotion) do |dev|
                dev.prefer_deployed_tasks(/avalon_actuators/)
            end

            robot do
                device(Dev::Controldev::Joystick, :as => 'joystick', :using => Controldev::JoystickTask)
            end

            define "sim", ::Simulation::Mars
            
            define "sim_setter", ::Simulation::MarsNodePositionSetter

            define 'motion_model', Localization::DeadReckoning.use(
                'hb' => thrusters_def,
                'ori' => imu_def
            )
            
            # Load AUV profile
            use_profile ::DFKI::Profiles::PoseEstimation,
                "orientation" => imu_def,
                "thruster_feedback" => thrusters_def,
                "motion_model" => motion_model_def,
                "depth" => imu_def 

            use Base::SonarScanProviderSrv => sonar_def
            
            
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

            # Load AUV profile
            use_profile ::DFKI::Profiles::PoseEstimation,
                "thruster_feedback" => thrusters_def,
                "motion_model" => motion_model_def,
                "depth" => imu_dev


            # Set local frame names
            ikf_orientation_estimator_def.use_frames(
                'imu' => 'imu',
                'fog' => 'fog',
                'body' => 'body'
            )

            ikf_orientation_estimator_def.ori_in_map_child.use_frames(
                'map' => 'map_halle',
                'world' => 'world_orientation'
            )

            initial_orientation_estimator_def.use_frames(
                'body' => 'body',
                'odometry' => 'local_orientation',
                'wall' => 'reference_wall',
                'world' => 'world_orientation',
                'sonar' => 'sonar'
            )

            initial_orientation_estimator_def.estimator_child.use_frames(
                'fog' => 'fog',
                'imu' => 'imu',
                'body' => 'body'
            )
    
            pose_estimator_def.use_frames(
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


            # Define dynamic transformation providers
            transformer do
                frames 'dvl', 'body'
                frames 'lbl', 'body'
                dynamic_transform initial_orientation_estimator_def.estimator_child, 'body' => 'local_orientation'
                dynamic_transform pose_estimator_blind_def, 'body' => 'map_halle'
                dynamic_transform pose_estimator_def, 'body' => 'map_halle'
                #dynamic_transform imu_dev, 'imu' => 'imu_nwu'
            end


            # Load AUV profile
            use_profile ::DFKI::Profiles::AUV,
                "final_orientation_with_z" => depth_fusion_def,
                "altimeter" => altimeter_dev,
                "thruster" => thrusters_def,
                "down_looking_camera" => bottom_camera_dev,
                "forward_looking_camera" => front_camera_dev,
                "pose_blind" => pose_estimator_blind_def,
                #"pose" => localization_def,
                "pose" => pose_estimator_def,
                "motion_model" => motion_model_def

#            use_profile ::DFKI::Profiles::AUV,
#                "final_orientation_with_z" => imu_def,
#                "altimeter" => altimeter_def,
#                "thruster" => thrusters_def,
#                "thruster_feedback" => thrusters_def,
#                "down_looking_camera" => bottom_camera_def,
#                "forward_looking_camera" => front_camera_def
#

        end
    end
end

