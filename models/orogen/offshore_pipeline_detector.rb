require "models/blueprints/control"
using_task_library 'auv_rel_pos_controller'


class OffshorePipelineDetector::Task
    argument :heading, :default => nil
    argument :depth, :default => nil
    argument :speed_x, :default => nil

    #TODO nothing?
    def configure
        super
        STDOUT.puts "Pipeline detector task got called with: #{self}"
        binding.pry
        orocos_task.depth = depth if depth
        orocos_task.prefered_heading = heading if heading
        orocos_task.default_x = speed_x if speed_x
    end

    def update_config
        binding.pry
        orocos_task.depth = depth if depth
        orocos_task.prefered_heading = heading if heading
        orocos_task.default_x = speed_x if speed_x
    end
end


class PipelineDetector < Syskit::Composition 
    argument :heading, :default => nil
    argument :depth, :default => nil
    argument :speed_x, :default => nil

    event :check_candidate
    event :follow_pipe
    event :found_pipe
    event :align_auv
    event :lost_pipe
    event :search_pipe
    event :end_of_pipe
    event :weak_signal


    add Base::ImageProviderSrv, :as => 'camera'
    add_main OffshorePipelineDetector::Task, :as => 'offshorePipelineDetector'
    add Base::OrientationWithZSrv, :as => "orienation_with_z"
    orienation_with_z_child.connect_to offshorePipelineDetector_child.orientation_sample_port
    camera_child.frame_port.connect_to offshorePipelineDetector_child

    export offshorePipelineDetector_child.position_command_port
    provides Base::AUVRelativeMotionControllerSrv, :as => 'controller'

#    attr_accessor :orientation_reader
    attr_accessor :pipeline_heading
    attr_accessor :last_valid_heading

    script do
        orientation_reader = orienation_with_z_child.orientation_z_samples_port.reader
        poll do
            if o = orientation_reader.read
                pipeline_heading = o.orientation.yaw
            end
#            transition!
        end
    end

    on :start do |event|
        binding.pry
        offshorePipelineDetector_child.speed_x = speed_x if speed_x
        offshorePipelineDetector_child.heading = heading if heading
        offshorePipelineDetector_child.depth = depth if depth
        offshorePipelineDetector_child.update_config
    end

    on :weak_signal do |event|
        self.last_valid_heading = pipeline_heading
    end

    on :end_of_pipe do |event|
        self.last_valid_heading = pipeline_heading
    end
end

class PipelineFollower < ::Base::ControlLoop
    add_main PipelineDetector, :as => "controller_local"

    overload 'controller', PipelineDetector 
    
    #begin workaround TODO @sylvain
    add AuvRelPosController::Task, :as => "workaround"
    controller_child.position_command_port.connect_to workaround_child 
    #end workaround


    argument :heading, :default => nil
    argument :depth, :default => nil
    argument :speed_x, :default => nil

    event :check_candidate
    event :follow_pipe
    event :found_pipe
    event :align_auv
    event :lost_pipe
    event :search_pipe
    event :end_of_pipe
    event :weak_signal


    on :start do |event|
        controller_child.speed_x = speed_x if speed_x
        controller_child.heading = heading if heading
        controller_child.depth = depth if depth
    end

#    pass_arguments_to_child my_child, :heading
#    forward_from_child my_child, :check_candidate
       
end
