require 'models/blueprints/avalon'
require 'models/blueprints/localization'

using_task_library 'auv_rel_pos_controller'
using_task_library 'wall_servoing'
using_task_library 'sonar_feature_estimator'

module Wall
    class Detector < Syskit::Composition


        add_main WallServoing::SingleSonarServoing, :as => 'detector'
        add Base::SonarScanProviderSrv, :as => 'sonar'
        add SonarFeatureEstimator::Task, :as => 'sonar_estimator'
        connect sonar_child => sonar_estimator_child
        add Base::OrientationWithZSrv, :as => "orienation_with_z"
	add_optional ::Localization::DeadReckoningSrv, :as => "dead_reckoning"
        connect orienation_with_z_child => detector_child.orientation_sample_port
        connect sonar_estimator_child => detector_child
	connect dead_reckoning_child => detector_child.position_sample_port
        #TODO Add motion model
        #connect XXX => detector_child.position_sample_child

        export detector_child.position_command_port
        provides Base::AUVRelativeMotionControllerSrv, :as => 'controller'


        event :wall_servoing
        event :searching_wall
        event :checking_wall
        event :detected_corner
        event :lost_all
        event :origin_alignment
        event :alignment_complete

        attr_accessor :num_corners

        on :start do |event|
            self.num_corners = 0
        end

        def corner_passed!
            @num_corners = @num_corners + 1 
        end

        on :detected_corner do |e|
            self.corner_passed!
            Robot.info "Passed one corner, have passed #{self.num_corners}"
        end


    end

    class Follower < ::Base::ControlLoop
        event :wall_servoing
        event :searching_wall
        event :checking_wall
        event :detected_corner
        event :lost_all
        event :origin_alignment
        event :alignment_complete

        add_main Detector, :as => "controller_local"
        overload 'controller', Detector

        argument :timeout, :default => nil
        argument :max_corners, :default => nil

        def num_corners
            controller_child.num_corners
        end

        on :start do |event|
            Robot.info "Starting Wall Servoing"
            @start_time = Time.now
            
            
            Robot.info "Starting wall detector reconfiguring sonar to wall_right"
            @sonar_workaround = true 
            @old_sonar_conf = sonar_child.conf
        end
        
        on :stop do |e|
            if not @sonar_workaround
                Robot.info "Stopping Wall Servoing, reconfigure it in prev_state"
                sonar_child.orocos_task.apply_conf(@old_sonar_conf,true)
            end
        end

        poll do
            if(self.timeout)
                if(@start_time + self.timeout < Time.now)
                    STDOUT.puts "Finished #{self} becaue time is over! #{@start_time} #{@start_time + self.timeout}"
                    emit :success
                end
            end
            if(self.max_corners)
                if(num_corners == self.max_corners)
                    Robot.info "Wall servoing succssfull get all corners"
                    emit :success
                end
            end

            #Workaround sonar configs
            if sonar_child.orocos_task.state == :RUNNING and @sonar_workaround
                if sonar_child.orocos_task.config.continous == 1 
                    STDOUT.puts "Overriding sonar config to wall right"
                    sonar_child.orocos_task.apply_conf(['default','wall_servoing_right'],true)
                    @sonar_workaround = false
                else
                    STDOUT.puts "Sonar config is fine did you solved the config issues? #{sonar_child.orocos_task.config.continous}"
                end
            end
        end
        
        
    end
end


