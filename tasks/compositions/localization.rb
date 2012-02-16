load_system_model 'tasks/data_services/base'

using_task_library 'eras_position_estimator'
using_task_library 'ekf_slam'

composition 'Localization' do
    abstract

    def self.estimator_type(name, &block)
        specialize 'pose_provider' => name do
            instance_eval(&block)
            provides Srv::GlobalPose
        end
    end

    add_main Srv::PoseEstimator, :as => 'pose_provider'
    add Srv::SpeedWithOrientationWithZ, :as => 'motion_provider'
    add Srv::OrientationWithZ
end


Cmp::Localization.estimator_type(ErasPositionEstimator::Task) do
   add Srv::SonarScanProvider, :as => 'sonar'
   add SonarFeatureEstimator::Task, :as => 'laserscan'

   overload 'motion_provider', Cmp::UwvModel

   event :reliable_position
   event :uncertain_position

   connect sonar => laserscan
   connect laserscan => pose_provider
   connect orientation_with_z => pose_provider.orientation_sample
   connect motion_provider => pose_provider.motion_sample

   export pose_provider.pose_sample
end

Cmp::Localization.estimator_type(EkfSlam::Task) do
    add Srv::SonarScanProvider, :as => 'sonar'

    overload 'motion_provider', Cmp::UwvModel
   
    connect orientation_with_z => pose_provider.orientation_samples
    connect orientation_with_z => pose_provider.depth_samples
    connect sonar => pose_provider

    export pose_provider.pose_samples
end
