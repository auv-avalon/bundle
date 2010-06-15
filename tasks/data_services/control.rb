import_types_from 'base'

data_service 'Driver'
data_service 'AUVDriver', :provides => Driver do
    output_port 'motion_commands', '/base/AUVMotionCommand'
end
data_service 'AUVVisualServoing', :provides => AUVDriver do
    input_port  'pose_samples',    '/wrappers/samples/RigidBodyState'
end

class Orocos::RobyPlugin::TaskContext
    # Specialized method to define a visual servoing class
    #
    # It associates the current task context model with its associated detector,
    # and provides a way to further specialize the AUVControlLoop composition
    # for this servoing controller
    def self.visual_servoing(detector, &block)
        provides AUVVisualServoing
        Orocos::RobyPlugin::Compositions::AUVControlLoop.specialize 'driver', self do
            add detector, :as => 'detector'

            # Auto-add some of the common inputs
            if detector.each_input.any? { |p| p.type_name =~ /base\/samples\/frame\/Frame\>/ }
                add ImageSource, :as => 'images'
            end
            if detector.each_input.any? { |p| p.type_name =~ /base\/samples\/frame\/FramePair\>/ }
                add LaserImagePairSource, :as => 'laser_images'
            end

            instance_eval(&block) if block_given?
            autoconnect
        end
    end
end

