
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
    camera_child.connect_to offshorePipelineDetector_child
    #TODO CONNECT

    #offshorePipelineDetector.altitude_samples.ignore
#    autoconnect

    export offshorePipelineDetector_child.position_command_port
    #provides Srv::AUVRelativeMotionController
    #provides Base::AUVRelativeMotionControlledSystemSrv, :as => 'controller'
    provides Base::AUVRelativeMotionControllerSrv, :as => 'controller'

    attr_reader :pipeline_heading

    on :start do |event|
        @orientation_reader = data_reader 'orientation_with_z', 'orientation_z_samples'
    end

    on :weak_signal do |event|
        if o = @orientation_reader.read
            @pipeline_heading = o.orientation.yaw
        end
    end

    on :end_of_pipe do |event|
        if !@pipeline_heading && (o = @orientation_reader.read)
            @pipeline_heading = o.orientation.yaw
        end
    end
end
