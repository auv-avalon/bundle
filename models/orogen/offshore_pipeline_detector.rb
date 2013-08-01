
class OffshorePipelineDetector::Task
    #TODO nothing?
end

class PipelineDetector < Syskit::Composition 

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
        orientation_reader = nil

        execute do
#            binding.pry
            #orientation_reader = orienation_with_z_child.orientation_z_samples_port.reader
            orientation_reader = orienation_with_z_child.orientation_samples_port.reader
        end

        poll do
            if o = orientation_reader.read
                pipeline_heading = o.orientation.yaw
            end
            transition!
        end
    end

    on :start do |event|
    end

    on :weak_signal do |event|
        self.last_valid_heading = pipeline_heading
    end

    on :end_of_pipe do |event|
        self.last_valid_heading = pipeline_heading
    end
end
