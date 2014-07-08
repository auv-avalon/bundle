require 'rock/models/blueprints/control'
require "models/blueprints/control"
require "models/blueprints/localization"
require "models/blueprints/avalon"
require "models/orogen/auv_control"

using_task_library 'auv_control'
module AuvCont

    ####### Konstants #####

    DELTA_YAW = 0.1
    DELTA_Z = 0.2
    DELTA_XY = 2
    DELTA_TIMEOUT = 2

    data_service_type 'WorldZRollPitchYawSrvVelocityXY' do
        input_port 'world_cmd', 'base/LinearAngular6DCommand'
        input_port 'Velocity_cmd', 'base/LinearAngular6DCommand'
    end
   
    class WorldPositionCmp < Syskit::Composition
        add ::Base::JointsCommandConsumerSrv, :as => "joint"
        add ::Base::PoseSrv, :as => "pose"
        add AuvControl::WorldToAligned.with_conf("default"), :as => "world_to_aligned"
        add AuvControl::OptimalHeadingController.with_conf("default"), :as => "optimal_heading_controller"
        add AuvControl::PIDController.prefer_deployed_tasks("aligned_position_controller"), :as => "aligned_position_controller"
        add AuvControl::PIDController.prefer_deployed_tasks("aligned_velocity_controller"), :as => "aligned_velocity_controller"
        add AuvControl::AlignedToBody, :as => "aligned_to_body"
        add AuvControl::AccelerationController, :as => "controller"
       # add ::Base::JointsStatusSrv, :as => "status_in"
        
        conf 'simulation', 'aligned_position_controller' => ['default', 'position_simulation_parallel'],
                           'aligned_velocity_controller' => ['default', 'velocity_simulation_parallel'],
                           'controller' => ['default_simulation']
        conf 'default', 'aligned_position_controller' => ['default', 'position'],
                           'aligned_velocity_controller' => ['default', 'velocity'],
                           'controller' => ['default']
        pose_child.connect_to world_to_aligned_child
        pose_child.connect_to aligned_position_controller_child
        pose_child.connect_to aligned_velocity_controller_child
        pose_child.connect_to aligned_to_body_child
        pose_child.connect_to optimal_heading_controller_child
        world_to_aligned_child.cmd_out_port.connect_to optimal_heading_controller_child.cmd_cascade_port
        optimal_heading_controller_child.cmd_out_port.connect_to aligned_position_controller_child.cmd_cascade_port
        aligned_position_controller_child.cmd_out_port.connect_to aligned_velocity_controller_child.cmd_cascade_port
        aligned_velocity_controller_child.cmd_out_port.connect_to aligned_to_body_child.cmd_cascade_port
        aligned_to_body_child.cmd_out_port.connect_to controller_child.cmd_cascade_port
        controller_child.connect_to joint_child

       # status_in_child.connect_to controller_child
        
        export world_to_aligned_child.cmd_in_port
        export controller_child.cmd_out_port
        export controller_child.status_in_port
        provides ::Base::WorldXYZRollPitchYawControlledSystemSrv, :as => "cmd_in"

        #TODO @Christian, wenn du hier "nur" ein CommandSrv definierst erfüllt das den controlloop ja nicht, das meinte ich schonmal
        provides ::Base::JointsControllerSrv, :as => "command_out"
        #provides ::Base::JointsCommandSrv, :as => "command_out"

    end
    class WorldAndXYVelocityCmp < Syskit::Composition
        add ::Base::JointsCommandConsumerSrv, :as => "joint"
        add ::Base::PoseSrv, :as => "pose"
        add AuvControl::WorldToAligned.with_conf("default"), :as => "world_to_aligned"
        add AuvControl::OptimalHeadingController.with_conf("default"), :as => "optimal_heading_controller"
        add AuvControl::PIDController.prefer_deployed_tasks("aligned_position_controller"), :as => "aligned_position_controller"
        add AuvControl::PIDController.prefer_deployed_tasks("aligned_velocity_controller"), :as => "aligned_velocity_controller"
        add AuvControl::AlignedToBody, :as => "aligned_to_body"
        add AuvControl::AccelerationController, :as => "controller"
        
        conf 'simulation', 'aligned_position_controller' => ['default', 'position_simulation_parallel'],
                           'aligned_velocity_controller' => ['default', 'velocity_simulation_parallel'],
                           'controller' => ['default_simulation']
        conf 'default', 'aligned_position_controller' => ['default', 'position'],
                           'aligned_velocity_controller' => ['default', 'velocity'],
                           'controller' => ['default']
        pose_child.connect_to world_to_aligned_child
        pose_child.connect_to aligned_position_controller_child
        pose_child.connect_to aligned_velocity_controller_child
        pose_child.connect_to aligned_to_body_child
        pose_child.connect_to optimal_heading_controller_child
        world_to_aligned_child.cmd_out_port.connect_to optimal_heading_controller_child.cmd_cascade_port
        optimal_heading_controller_child.cmd_out_port.connect_to aligned_position_controller_child.cmd_cascade_port
        aligned_position_controller_child.cmd_out_port.connect_to aligned_velocity_controller_child.cmd_cascade_port
        aligned_velocity_controller_child.cmd_out_port.connect_to aligned_to_body_child.cmd_cascade_port
        aligned_to_body_child.cmd_out_port.connect_to controller_child.cmd_cascade_port
        controller_child.connect_to joint_child
        
        export world_to_aligned_child.cmd_in_port, :as => 'world_in'
        export aligned_velocity_controller_child.cmd_in_port, :as => 'velocity_in'
        export controller_child.cmd_out_port
        provides ::Base::WorldZRollPitchYawControlledSystemSrv, :as => "world_in_s", "command_in" => "velocity_in"
        provides ::Base::XYVelocityControlledSystemSrv, :as => "velocity_in_s", "command_in" => "world_in"
        provides ::Base::JointsCommandSrv, :as => "command_out"
    end
    
    ::Base::ControlLoop.specialize ::Base::ControlLoop.controller_child => WorldPositionCmp
    ::Base::ControlLoop.specialize ::Base::ControlLoop.controller_child => WorldAndXYVelocityCmp
=begin
    class WorldZRollPitchYawVelocityXY < ::Base::ControlLoop
        add ::Base::JointsCommandConsumerSrv, :as => "joint_srv"
        add ::Localization::ParticleDetector, :as => "pose"
        add AuvCont::WorldToAligned.with_conf("default","ZRollPitchYaw"), :as => "world_to_aligned"
        add AuvCont::PIDController.with_conf("default","aligned","position","ZRollPitchYaw"), :as => "aligned_position_controller"
        add AuvCont::PIDController.with_conf("default","aligned","velocity","all"), :as => "aligned_velocity_controller"
        add AuvCont::AlignedToBody, :as => "aligned_to_body"
        add AuvCont::AccelerationController, :as => "acceleration_controller"
        
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

######## Movements ##################################

    class PositionMove < ::Base::ControlLoop
        overload 'controller', AuvControl::ConstantCommand

        argument :heading, :default => 0
        argument :depth, :default => -4 
        argument :x, :default => 0
        argument :y, :default => 0
        argument :timeout, :default => nil
        argument :finish_when_reached, :default => nil #true when it should success, if nil then this composition never stops based on the position
        argument :event_on_timeout, :default => :success
        argument :delta_xy, :default => DELTA_XY
        argument :delta_z, :default => DELTA_Z
        argument :delta_yaw, :default => DELTA_YAW
        argument :delta_timeout, :default => DELTA_TIMEOUT
    
        attr_reader :start_time

        add Base::PoseSrv, :as => 'pose'
        
        on :start do |ev|
                reader_port = nil
                if pose_child.has_port?('pose_samples')
                    reader_port = pose_child.pose_samples_port
                else
                    pose_child.each_child do |c| 
                        if c.has_port?('pose_samples')
                            reader_port = c.pose_samples_port
                            break
                        end
                    end
                end
                @reader = reader_port.reader 
                @start_time = Time.now
                Robot.info "Starting Position moving #{self}"
                cmd = controller_child.cmd
                cmd.linear[0] = x
                cmd.linear[1] = y
                cmd.linear[2] = depth

                cmd.angular[0] = 0 #roll
                cmd.angular[1] = 0 #pitch
                cmd.angular[2] = heading #jaw
                controller_child.cmd = cmd
                #controller_child.update_config(:x => x, :heading => heading, :z=> depth, :y => y, :pitch => 0, :roll => 0)
                @last_invalid_post = Time.new
        end
        
        poll do
            @last_invalid_pose = Time.new if @last_invalid_pose.nil?
            @start_time = Time.now if @start_time.nil?
            if @start_time.my_timeout?(self.timeout)
                Robot.info  "Finished Pos Mover because time is over! #{@start_time} #{@start_time + self.timeout}"
                emit event_on_timeout 
            end

            if finish_when_reached
                if @reader
                    if pos = @reader.read
                        if 
                            pos.position[0].x_in_range(x,delta_xy) and
                            pos.position[1].y_in_range(y,delta_xy) and
                            pos.position[2].depth_in_range(depth,delta_z) and
                            pos.orientation.yaw.angle_in_range(heading,delta_yaw)
                                @reached_position = true
                                if @last_invalid_pose.delta_timeout?(delta_timeout) 
                                    Robot.info "Hold Position, recalculating"
                                    emit :success
                                end
                        else
                            if @reached_position
                                Robot.info "################### Bad Pose! ################" 
                            end
                            @last_invalid_pose = Time.new
                            @reached_position = false
                        end
                    end
                end
            end
        end

    end
end
    

