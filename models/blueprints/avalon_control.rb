require "models/blueprints/control"
require "models/blueprints/avalon"

using_task_library "auv_rel_pos_controller"
using_task_library "avalon_control"
using_task_library "depth_reader"
using_task_library "controldev"
using_task_library "raw_control_command_converter"


module AvalonControl
    DELTA_YAW = 0.1
    DELTA_Z = 0.2
    DELTA_XY = 2
    DELTA_TIMEOUT = 2

    Base::ControlLoop.specialize Base::ControlLoop.controller_child => AvalonControl::PositionControlTask do
        add Base::PoseSrv, :as => "pose"
        pose_child.connect_to controller_child
    end
    
    Base::ControlLoop.specialize Base::ControlLoop.controller_child => AuvRelPosController::Task do
        add Base::OrientationWithZSrv, :as => "orientation_with_z"
        orientation_with_z_child.connect_to controller_child
    end

    Base::ControlLoop.specialize Base::ControlLoop.controller_child => AvalonControl::MotionControlTask do
        add Base::OrientationWithZSrv, :as => 'pose'
        add Base::GroundDistanceSrv, :as => 'dist'
        connect pose_child.orientation_z_samples_port => controller_child.pose_samples_port
        #connect dist_child.distance_port => controller_child.ground_distance_port
    end

    #Other way to realize error forwarding
    #using_task_library 'hbridge'
    #Base::ControlLoop.specialize Base::ControlLoop.controlled_system_child => Hbridge::Task do
    #    overload 'controlled_system', Hbridge::Task, :failure => :timeout.or(:stop)
    #end

    class JoystickCommandCmp < Syskit::Composition 
        add Base::RawCommandControllerSrv, :as => 'rawCommand'
        add Base::OrientationWithZSrv, :as => 'orientation_with_z'
        add RawControlCommandConverter::Movement, :as => 'rawCommandConverter'
        add Base::GroundDistanceSrv, :as => 'dist'
        connect rawCommand_child => rawCommandConverter_child
        connect dist_child.distance_port => rawCommandConverter_child.ground_distance_port
        connect orientation_with_z_child.orientation_z_samples_port => rawCommandConverter_child.orientation_readings_port

        export rawCommandConverter_child.motion_command_port
        export rawCommandConverter_child.world_command_port, :as => "WorldCommand"
        export rawCommandConverter_child.aligned_velocity_command_port, :as =>"VeloCommand"
        
        provides Base::AUVMotionControllerSrv, :as => "controller"

    end

    class DephFusionCmp < Syskit::Composition
        add ::Base::ZProviderSrv, :as => 'z'
        add ::Base::OrientationSrv, :as => 'ori'
        add DepthReader::DepthAndOrientationFusion, :as => 'task'
    
        connect z_child => task_child.depth_samples_port
        connect ori_child => task_child.orientation_samples_port
    
        export task_child.pose_samples_port
        provides ::Base::OrientationWithZSrv, :as => "orientation_with_z"
    end
    
    class SimpleMove < ::Base::ControlLoop
        overload 'controller', AvalonControl::FakeWriter 
        
        argument :heading, :default => nil
        argument :depth, :default => nil
        argument :speed_x, :default => nil
        argument :speed_y, :default => nil
        argument :timeout, :default => nil
        argument :finish_when_reached, :default => nil #true when it should success, if nil then this composition never stops based on the position
        argument :event_on_timeout, :default => :success
        argument :delta_z, :default => DELTA_Z 
        argument :delta_yaw, :default => DELTA_YAW
        argument :delta_timeout, :default => DELTA_TIMEOUT 

        attr_reader :start_time
        add Base::OrientationWithZSrv, :as => "reading"

        on :start do |ev|
                @start_time = Time.now
                Robot.info "Starting Drive simple #{self}"
                erg = controller_child.update_config(:speed_x => speed_x, :heading => heading, :depth=> depth, :speed_y => speed_y)
                #@reader = reading_child.orientation_samples_port.reader
                @reader = reading_child.pose_samples_port.reader 
                @last_invalid_pose = Time.new
                Robot.info "Updated config returned #{erg}"
        end
        
        poll do
            if(self.timeout)
                if(@start_time + self.timeout < Time.now)
                    Robot.info "Finished Simple Move becaue time is over! #{@start_time} #{@start_time + self.timeout}"
                    emit event_on_timeout 
                end
            end
            if finish_when_reached
                if @reader
                    if pos = @reader.read
                        if 
                            (pos.position[2] - depth).abs < delta_z and
                            (pos.orientation.yaw - heading).abs < delta_yaw #TODO WARNING make this correct under respect of wraps
                                if (@last_invalid_pose + delta_timeout) < Time.new
                                    emit :success
                                end
                        else
                            @last_invalid_pose = Time.new
                        end
                    end
                end
            end
        end
    end
    
    class SimplePosMove < ::Base::ControlLoop
        overload 'controller', AvalonControl::RelFakeWriter

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
                @reader = pose_child.pose_samples_port.reader 
                @start_time = Time.now
                Robot.info "Starting Position moving #{self}"
                controller_child.update_config(:x => x, :heading => heading, :depth=> depth, :y => y)
                @last_invalid_post = Time.new
        end
        
        poll do
            if self.timeout
                if(@start_time + self.timeout < Time.now)
                    Robot.info  "Finished Pos Mover because time is over! #{@start_time} #{@start_time + self.timeout}"
                    emit event_on_timeout 
                end
            end

            if finish_when_reached
                if @reader
                    if pos = @reader.read
                        if 
                            (pos.position[0] - x).abs < delta_xy and
                            (pos.position[1] - y).abs < delta_xy and
                            (pos.position[2] - depth).abs < delta_z and
                            (pos.orientation.yaw - heading).abs < delta_yaw #TODO WARNING make this correct under respect of wraps
                                current_timeout = (@last_invalid_pose + delta_timeout - Time.now).to_i
                                @last_timeout = 0 if @last_timeout.nil?
                                Robot.info "Got there, timeout in #{(@last_invalid_pose + delta_timeout - Time.now).to_i}" if (current_timeout - @last_timeout) >= 1
                                @last_timeout = current_timeout if (current_timeout - @last_timeout) >= 1
                                @reached_position = true
                                if (@last_invalid_pose + delta_timeout) < Time.new
                                    Robot.info "Hold Position, recalculating"
                                    emit :success
                                end
                        else
                            Robot.info "################### Bad Pose! ################" if @reached_position
                            @last_invalid_pose = Time.new
                            @reached_position = false
                        end
                    end
                end
            end
        end

    end

end
