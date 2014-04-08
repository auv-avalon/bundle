require 'models/blueprints/avalon'
require 'models/blueprints/avalon_control'
using_task_library 'auv_rel_pos_controller'
using_task_library 'uw_particle_localization'
using_task_library 'sonar_feature_estimator'
using_task_library 'hbridge'
using_task_library 'sonar_wall_hough'


module Localization

    data_service_type 'HoughSrv' do
        output_port "position", "/base/samples/RigidBodyState"
        output_port "orientation_drift", "double"
    end
    
    data_service_type 'DeadReckoningSrv' do
	  output_port "position", "/base/samples/RigidBodyState"
    end

    class ParticleDetector < Syskit::Composition
        add UwParticleLocalization::Task, :as => 'main'
        add Base::SonarScanProviderSrv, :as => 'sonar'
        add SonarFeatureEstimator::Task, :as => 'sonar_estimator'
        add ::Base::OrientationWithZSrv, :as => 'ori'
        #add Dev::Sensors::Hbridge, :as => 'hb'
        #add Base::JointsStatusSrv, :as => 'hb'
        add Base::JointsControllerSrv, :as => 'hb'
        add_optional ::Localization::HoughSrv, as: 'hough'

        connect sonar_child => sonar_estimator_child
        connect ori_child => sonar_estimator_child.orientation_sample_port
        connect ori_child => main_child.orientation_samples_port
        connect sonar_estimator_child => main_child
        connect hb_child => main_child
        connect hough_child => main_child.pose_update_port

        export main_child.pose_samples_port
        provides Base::PoseSrv, :as => 'pose'
    end

    class DeadReckoning < Syskit::Composition
	add UwParticleLocalization::MotionModel, :as => 'main'
	add ::Base::OrientationWithZSrv, :as => 'ori'
	add Base::JointsControllerSrv, :as => 'hb'
	
	connect ori_child => main_child
	connect hb_child => main_child
	
	export main_child.pose_samples_port
	provides DeadReckoningSrv, :as => 'pose'
    end
    
    class HoughDetector < Syskit::Composition
        add SonarWallHough::Task, as: 'main'
        add Base::SonarScanProviderSrv, as: 'sonar'
        add Base::OrientationSrv, as: 'ori'
        add_optional Localization::DeadReckoning, as: 'dead'

        connect sonar_child => main_child
        connect ori_child => main_child
        connect dead_child => main_child

        export main_child.position_port, as: 'position'
        export main_child.orientation_drift_port, as: 'ori_drift'
        provides HoughSrv, as: 'hough'
    end
               
    class HoughParticleDetector < Syskit::Composition
        add ParticleDetector.use(Localization::HoughDetector), :as => 'main'
        #add Localization::HoughDetector.use(Localization::ParticleDetector), as: 'hough'
        add Localization::HoughDetector, as: 'hough'
        
        export main_child.pose_samples_port
        provides Base::PoseSrv, as: 'pose'

    end

#    class Follower < ::Base::ControlLoop
#        add_main AvalonControl::RelFakeWriter, :as => "controller_local" 
##        add_main ParticleDetector, :as => "controller_local"
#        overload 'controller', AvalonControl::RelFakeWriter
#
#        
##        overload 'controlled_system', 
#
##        argument :timeout, :default => nil
##        argument :heading, :default => 0
##        argument :pos_x, :default => 0
##        argument :pos_y, :default => 0
##        argument :pos_z, :default => 0
#
##        attr_reader :start_time
##
##        on :start do |event|
##            Robot.info "Starting Position Mover"
##            @start_time = Time.now
##        end
#
##        script do
##            binding.pry
##            port = controlled_system_child.find_port("command_in")
##            position_writer = controlled_system_child.command_in_port.writer
##            sample = position_writer.sample.new
##            sample.x = pos_x
##            sample.y = pos_y
##            sample.z = pos_z
##            sample.heading = pos_heading
##            poll do
##                position_writer.write sample
##            end
##        end
#
##        poll do
##            if(self.timeout)
##                if(@start_time + self.timeout < Time.now)
##                    STDOUT.puts "Finished #{self} becaue time is over! #{@start_time} #{@start_time + self.timeout}"
##                    emit :success
##                end
##            end
##
##        end
#    end
#
##        argument :turn_dir, :default => nil
##        argument :heading, :default => nil
##        argument :depth, :default => nil
##        argument :speed_x, :default => nil
##        argument :timeout, :default => nil
#
##        event :check_candidate
##        event :follow_pipe
##        event :found_pipe
##        event :align_auv
##        event :lost_pipe
##        event :search_pipe
##        event :end_of_pipe
##        event :weak_signal
##        attr_reader :start_time
##
##        on :start do |event|
##            Robot.info "Starting Pipeline Follower with config: speed_x: #{speed_x}, heading: #{heading}, depth: #{depth}"
##            controller_child.update_config(:speed_x => speed_x, :heading => heading, :depth=> depth, :turn_dir => turn_dir)
##            @start_time = Time.now
##        end
end

