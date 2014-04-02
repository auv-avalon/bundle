require 'models/blueprints/auv_control_services'
require 'rock/models/blueprints/control'
require "models/blueprints/control"
require "models/blueprints/localization"

using_task_library 'auv_control'

module AuvControl
    class WorldPosition < ::Base::ControlLoop
        add ::Base::JointsCommandConsumerSrv, :as => "joint_srv"
        add ::Localization::ParticleDetector, :as => "pose"

        add AuvControl::WorldToAligned.with_conf("default","all"), :as => "world_to_aligned"
        add AuvControl::OptimalHeadingController.with_conf("default","all"), :as => "optimal_heading_controller"
        add AuvControl::PIDController.with_conf("default","aligned","position","all"), :as => "aligned_position_controller"
        add AuvControl::PIDController.with_conf("default","aligned","velocity","all"), :as => "aligned_velocity_controller"
        add AuvControl::AlignedToBody, :as => "aligned_to_body"
        add AuvControl::AccelerationController, :as => "acceleration_controller"
        
        pose_child.connect_to world_to_aligned_child
        pose_child.connect_to aligned_position_controller_child
        pose_child.connect_to aligned_velocity_controller_child
        pose_child.connect_to aligned_to_body_child

        world_to_aligned_child.cmd_out_port.connect_to optimal_heading_controller_child.cmd_cascade_port
        optimal_heading_controller_child.cmd_out_port.connect_to aligned_position_controller_child.cmd_cascade_port
        aligned_position_controller_child.cmd_out_port.connect_to aligned_velocity_controller_child.cmd_cascade_port
        aligned_velocity_controller_child.cmd_out_port.connect_to aligned_to_body_child.cmd_cascade_port
        aligned_to_body_child.cmd_out_port.connect_to acceleration_controller_child.cmd_cascade_port

        acceleration_controller_child.cmd_out_port.connect_to joint_srv_child 
        
        export world_to_aligned_child.cmd_in_port
        provides WorldXYZRollPitchYawSrv, :as => "cmd_in"
    end
=begin
    class WorldZRollPitchYawVelocityXY < ::Base::ControlLoop
        add ::Base::JointsCommandConsumerSrv, :as => "joint_srv"
        add ::Localization::ParticleDetector, :as => "pose"

        add AuvControl::WorldToAligned.with_conf("default","ZRollPitchYaw"), :as => "world_to_aligned"
        add AuvControl::PIDController.with_conf("default","aligned","position","ZRollPitchYaw"), :as => "aligned_position_controller"
        add AuvControl::PIDController.with_conf("default","aligned","velocity","all"), :as => "aligned_velocity_controller"
        add AuvControl::AlignedToBody, :as => "aligned_to_body"
        add AuvControl::AccelerationController, :as => "acceleration_controller"
        
        pose_child.connect_to world_to_aligned_child
        pose_child.connect_to aligned_position_controller_child
        pose_child.connect_to aligned_velocity_controller_child
        pose_child.connect_to aligned_to_body_child

        world_to_aligned_child.cmd_out_port.connect_to aligned_position_controller_child.cmd_cascade_port
        aligned_position_controller_child.cmd_out_port.connect_to aligned_velocity_controller_child.cmd_cascade_port
        aligned_velocity_controller_child.cmd_out_port.connect_to aligned_to_body_child.cmd_cascade_port
        aligned_to_body_child.cmd_out_port.connect_to acceleration_controller_child.cmd_cascade_port

        acceleration_controller_child.cmd_out_port.connect_to joint_srv_child 
        
        export world_to_aligned_child.cmd_in_port
        export aligned_velocity_controller_child.cmd_in_port
        provides WorldZRollPitchYawSrvVelocityXY, :as => "cmd_in"
        
    end
=end
end
    
