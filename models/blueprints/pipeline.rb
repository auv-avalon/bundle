using_task_library 'auv_rel_pos_controller'
using_task_library 'offshore_pipeline_detector'

module Pipeline
    class Detector < Syskit::Composition 
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

        attr_accessor :pipeline_heading
        attr_accessor :last_valid_heading

        script do
            orientation_reader = orienation_with_z_child.orientation_z_samples_port.reader
            poll do
                if o = orientation_reader.read
                    pipeline_heading = o.orientation.yaw
                end
            end
        end

        def update_config(options)
            offshorePipelineDetector_child.update_config(options)
        end

        on :weak_signal do |event|
            self.last_valid_heading = pipeline_heading
        end

        on :end_of_pipe do |event|
            Robot.info "got End of pipe Event"
            self.last_valid_heading = pipeline_heading
        end
    end

    class Follower < ::Base::ControlLoop

        #instead of adding it here:
        add_main Detector, :as => "controller_local"
        #implement something like this:
    #    pass_arguments_to_child my_child, :heading
    #    forward_from_child my_child, :check_candidate

        overload 'controller', Detector 
        
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
            Robot.info "Starting Pipeline Follower with config: speed_x: #{speed_x}, heading: #{heading}, depth: #{depth}"
            controller_child.update_config(:speed_x => speed_x, :heading => heading, :depth=> depth)
        end

           
    end
end
