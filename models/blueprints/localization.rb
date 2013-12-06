using_task_library 'uw_particle_localization'
using_task_library 'sonar_feature_estimator'
using_task_library 'hbridge'


module Localization
    class ParticleDetector < Syskit::Composition
        add UwParticleLocalization::Task, :as => 'main'
        add Base::SonarScanProviderSrv, :as => 'sonar'
        add SonarFeatureEstimator::Task, :as => 'sonar_estimator'
        add ::Base::OrientationSrv, :as => 'ori' 
        add Base::ActuatorControlledSystemSrv, :as => 'hb' 
        connect sonar_child => sonar_estimator_child
        connect ori_child => sonar_estimator_child
        connect sonar_estimator_child => main_child
        connect hb_child => main_child
    end

    class Controller < ::Base::ControlLoop
        add_main ParticleDetector, :as => "controller_local"
        overload 'controller', ParticleDetector
    end

#        argument :turn_dir, :default => nil
#        argument :heading, :default => nil
#        argument :depth, :default => nil
#        argument :speed_x, :default => nil
#        argument :timeout, :default => nil

#        event :check_candidate
#        event :follow_pipe
#        event :found_pipe
#        event :align_auv
#        event :lost_pipe
#        event :search_pipe
#        event :end_of_pipe
#        event :weak_signal
#        attr_reader :start_time
#
#        on :start do |event|
#            Robot.info "Starting Pipeline Follower with config: speed_x: #{speed_x}, heading: #{heading}, depth: #{depth}"
#            controller_child.update_config(:speed_x => speed_x, :heading => heading, :depth=> depth, :turn_dir => turn_dir)
#            @start_time = Time.now
#        end
end

