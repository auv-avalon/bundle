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
end

