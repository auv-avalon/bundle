using_task_library 'avalon_control'
using_task_library 'ekf_slam'
using_task_library 'low_level_driver'
using_task_library 'xsens_imu'
using_task_library 'dsp3000'
using_task_library 'state_estimator'
using_task_library 'structured_light'
using_task_library 'offshore_pipeline_detector'
using_task_library 'sonardetector'
using_task_library 'buoydetector'
using_task_library 'frame_demultiplexer'
using_task_library 'controldev'
using_task_library 'raw_control_command_converter'
using_task_library 'rotation_experiment'

# Composition that extracts the normal camera stream out of a "structured light"
# stream
composition 'StructuredLightCamera' do
    add Srv::ImageProvider
    add FrameDemultiplexer::Task, :as => 'demux'
    export demux.oframe
    provides Srv::ImageProvider
    autoconnect
end

# Composition that extracts the stream out of a "structured light"
# stream
composition 'StructuredLightInput' do
    add Srv::ImageProvider
    add FrameDemultiplexer::Task, :as => 'demux'
    export demux.oframe_pair
    provides Srv::StructuredLightPair
    autoconnect
end

composition 'PoseEstimator' do
    add EkfSlam::Task, :as => 'slam'

    add Srv::Orientation
    connect orientation => slam.orientation_samples
    add Srv::ZProvider
    connect z_provider => slam.depth_samples
    add Srv::SonarScanProvider
    connect sonar_scan_provider => slam.SonarScan

    export slam.pose_samples
    provides DataServices::Pose
end

composition "OrientationEstimator" do
    add StateEstimator::Task, :as => 'estimator'

    add Srv::ZProvider
    connect z_provider => estimator.depth_samples
    add XsensImu::Task, :as => 'imu'
    connect imu => estimator.orientation_samples_imu
    connect imu => estimator.imu_sensor_samples
    add Dsp3000::Task, :as => 'fog'
    connect fog => estimator.fog_samples

    export estimator.orientation_samples
    provides Srv::OrientationWithZ
end

composition 'StructuredLight' do
    add Srv::StructuredLightPair
    add StructuredLight::Task, :as => 'structuredLight'

    export structuredLight.laser_scan
    provides Srv::LaserRangeFinder
    autoconnect
end

composition 'PipelineDetector' do
    event :check_candidate
    event :follow_pipe
    event :found_pipe
    event :align_auv
    event :lost_pipe
    event :search_pipe
    event :end_of_pipe

    add Srv::ImageProvider
    add_main OffshorePipelineDetector::Task, :as => 'offshorePipelineDetector'
    add Srv::OrientationWithZ
    offshorePipelineDetector.altitude_samples.ignore
    autoconnect

    export offshorePipelineDetector.position_command
    provides Srv::RelativePositionDetector
end

composition 'BuoyDetector' do
    add Srv::ImageProvider
    add Srv::OrientationWithZ
    add Buoydetector::Task, :as => 'detector'
    autoconnect

    export detector.relative_position
    provides Srv::RelativePositionDetector
end

composition 'WallDetector' do
    add Srv::SonarScanProvider
    add Sonardetector::Task , :as => 'detector'
    add Srv::Orientation
    autoconnect

    export detector.position_command
    provides Srv::RelativePositionDetector
end

composition 'Rotation' do
    add Srv::ImageProvider
    add Srv::OrientationWithZ
    add_main RotationExperiment::Task, :as => 'rotator'
    autoconnect

    export rotator.position_command

end

