CONFIG_HACK = 'simulation'
require "auv/models/profiles/main"
require "models/blueprints/auv"
require "models/blueprints/pose_auv"
#require "rock_auv/models/blueprints/control"

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

            use Base::SonarScanProviderSrv => sonar_def

            # Define dynamic transformation providers
            transformer do
                dynamic_transform imu_def, 'body' => 'odometry'
            end

            use_profile ::DFKI::Profiles::AUV,
                "orientation_with_z" => imu_def,
                "altimeter" => altimeter_def,
                "thruster" => thrusters_def,
                "down_looking_camera" => bottom_camera_def,
                "forward_looking_camera" => front_camera_def,
                "pose_blind" => imu_def,
                "pose" => imu_def,
                "motion_model" => motion_model_def

        end
    end
end

