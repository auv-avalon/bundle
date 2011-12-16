using_task_library 'avalon_control'
# using_task_library 'auv_control'
using_task_library 'ekf_slam'
using_task_library 'depth_reader'
using_task_library 'xsens_imu'
using_task_library 'fog_kvh'
using_task_library 'state_estimator'
using_task_library 'orientation_estimator'
using_task_library 'structured_light'
using_task_library 'offshore_pipeline_detector'
using_task_library 'buoydetector'
using_task_library 'frame_demultiplexer'
using_task_library 'controldev'
using_task_library 'raw_control_command_converter'
using_task_library 'pipline_tracker'
using_task_library 'motion_estimation'
using_task_library 'sonar_tritech'
# using_task_library 'rotation_experiment'

# using_task_library 'asv_detector'
# using_task_library 'low_level_driver'

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
    add XsensImu::Task, :as => 'imu'
    add FogKvh::Dsp3000Task, :as => 'fog'

    connect z_provider => estimator.depth_samples
    connect imu => estimator.orientation_samples_imu
    connect imu => estimator.imu_sensor_samples
    connect fog => estimator.fog_samples

    export estimator.orientation_samples, :as => 'orientation_z_samples'
    provides Srv::OrientationWithZ
end

composition "DagonOrientationEstimator" do
    add OrientationEstimator::Task, :as => 'estimator'

    add XsensImu::Task, :as => 'imu'
    add FogKvh::Dsp3000Task, :as => 'fog'

    connect imu => estimator.xsens_samples
    connect imu => estimator.xsens_orientation
    connect fog => estimator.fog_samples

    export estimator.attitude_b_g, :as => 'orientation_samples'
    provides Srv::Orientation
end

composition 'StructuredLight' do
    add Srv::StructuredLightPair
    add StructuredLight::Task, :as => 'structuredLight'

    export structuredLight.laser_scan
    provides Srv::LaserRangeFinder
    autoconnect
end
composition 'PipelineSonarDetector' do
    add Srv::OrientationWithZ
    add SonarTritech::Profiling
    add Srv::Actuators
    add Srv::RawCommand#, :as => 'rawCommand'  #needed only for debugging
    add_main PiplineTracker::Task, :as => 'detector'
   # add PiplineTracker::Task, :as => "detector"
    autoconnect
    export detector.position_command
    provides Srv::RelativePositionDetector
end

composition 'PipelineDetector' do
    event :check_candidate
    event :follow_pipe
    event :found_pipe
    event :align_auv
    event :lost_pipe
    event :search_pipe
    event :end_of_pipe
    event :weak_signal

    add Srv::ImageProvider
    add_main OffshorePipelineDetector::Task, :as => 'offshorePipelineDetector'
    add Srv::OrientationWithZ
    offshorePipelineDetector.altitude_samples.ignore
    autoconnect

    export offshorePipelineDetector.position_command
    provides Srv::RelativePositionDetector

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


#class Orocos::RobyPlugin::PiplineTracker::Task
#    on :start do |event|
#        Robot.info "overloading configuration of #{self}"
#        #control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first.orogen_task
#        #pid = control_task.controller_y
#        #pid.Ti = 0.001
#        #pid.
#        #control_task.controller_y = pid
#
#        #control_task.controller_x = pid
#        control_task.reset
#    end
#
#    on :stop do |event|
#        Robot.info "resetting configuration"
#        #control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first.orogen_task
#        #pid = control_task.controller_y
#        #pid.Ti = 0
#        #control_task.controller_y = pid
#        #control_task.reset
#    end
#end


class Orocos::RobyPlugin::OffshorePipelineDetector::Task
    on :start do |event|
        Robot.info "overloading configuration of #{self}"
        control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first.orogen_task
        pid = control_task.controller_y
        pid.Ti = 0.001
        control_task.controller_y = pid
        control_task.reset
    end

    on :stop do |event|
        Robot.info "resetting configuration"
        control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first.orogen_task
        pid = control_task.controller_y
        pid.Ti = 0
        control_task.controller_y = pid
        control_task.reset
    end
end

Cmp::VisualServoing.specialize 'detector' => Cmp::PipelineDetector do
    overload 'detector', Cmp::PipelineDetector,
        :success => :end_of_pipe,
        :remove_when_done => false
end

composition 'BuoyDetector' do
    event :buoy_detected
    event :buoy_lost
    event :buoy_arrived
    event :strafe_start
    event :strafe_finished
    event :strafe_error
    event :moving_to_cutting_distance
    event :cutting
    event :cutting_success
    event :cutting_error

    add Srv::ImageProvider
    add Srv::OrientationWithZ    
    add_main Buoydetector::Task, :as => 'detector'
    autoconnect

    export detector.relative_position
    provides Srv::RelativePositionDetector
end


Cmp::VisualServoing.specialize 'detector' => Cmp::BuoyDetector do
    event :failed_to_find_buoy
    forward :failed_to_find_buoy => :failed
    event :behaviour_failure
    forward :behaviour_failure => :failed

    event :failed_to_approach
    forward :failed_to_approach => :behaviour_failure
    event :failed_to_strafe
    forward :failed_to_strafe => :behaviour_failure
    event :failed_to_cut
    forward :failed_to_cut => :behaviour_failure
    event :buoy_lost
    forward :buoy_lost => :behaviour_failure
end

composition 'WallDetector' do
#    event :wall_found
#
#    add Srv::SonarScanProvider
#    add Srv::Orientation
#    add_main Sonardetector::Task , :as => 'detector'
#    autoconnect
#
#    export detector.position_command
#    provides Srv::RelativePositionDetector
end

composition 'AsvDetector' do
#    event :asv_found
#    event :asv_lost

#    add Srv::ImageProvider
#    add_main AsvDetector::Task, :as => 'detector'
#    autoconnect

#    export detector.position_command
#    provides Srv::RelativePositionDetector
end

composition 'Rotation' do
#    add Srv::ImageProvider
#    add Srv::OrientationWithZ
#    add_main RotationExperiment::Task, :as => 'rotator'
#    autoconnect

#    export rotator.position_command
end


composition 'MotionEstimation' do
    add Srv::Actuators
    add Srv::OrientationWithZ
    add MotionEstimation::Task, :as => "motion"
    export motion.speed_samples
    autoconnect
    provides Srv::SpeedWithOrientationWithZ
end
