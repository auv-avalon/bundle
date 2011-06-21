using_task_library 'avalon_control'
using_task_library 'ekf_slam'
using_task_library 'low_level_driver'
using_task_library 'xsens_imu'
using_task_library 'dsp3000'
using_task_library 'state_estimator'
using_task_library 'structured_light'
using_task_library 'offshore_pipeline_detector'
using_task_library 'sonardetector'
using_task_library 'frame_demultiplexer'

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

composition 'PoseEstimation' do
    add Srv::Orientation
    add EkfSlam::Task, :as => 'slam'
    add SonarDriver::Micron 
    slam.acceleration_samples.ignore

    export slam.pose_samples
    provides DataServices::Pose
    autoconnect
end

composition "OrientationEstimator" do
    add LowLevelDriver::LowLevelTask, :as => 'lowlevel'
    add XsensImu::Task, :as => 'imu'
    add Dsp3000::Task, :as => 'fog'
    add StateEstimator::Task, :as => 'stateestimator'

    export stateestimator.orientation_samples #do this before provides
    provides Srv::OrientationWithZ

    fog.orientation_samples.ignore
    stateestimator.position_samples.ignore
    connect fog.rotation => stateestimator.fog_samples
    autoconnect
end

composition 'StructuredLight' do
    add Srv::StructuredLightPair
    add StructuredLight::Task, :as => 'structuredLight'

    export structuredLight.laser_scan
    provides Srv::LaserRangeFinder
    autoconnect
end

composition 'PipelineDetector' do
    add Srv::ImageProvider
    add OffshorePipelineDetector::Task, :as => 'offshorePipelineDetector'
    autoconnect

    export offshorePipelineDetector.position_command
    provides Srv::RelativePositionDetector
end

composition 'WallDetector' do
    add SonarDriver::Micron, :as => "sonar"
    add Sonardetector::Task , :as => 'detector'
    connect sonar.BaseScan => detector.sonar_input

    export detector.virtual_point
    provides Srv::ObjectPointDetector
end

