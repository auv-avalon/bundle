load_system_model 'tasks/compositions/main'

using_task_library 'avalon_control'
using_task_library 'ekf_slam'
using_task_library 'depth_reader'
using_task_library 'xsens_imu'
using_task_library 'modem_can'
using_task_library 'gps'
using_task_library 'fog_kvh'
using_task_library 'state_estimator'
using_task_library 'orientation_estimator'
using_task_library 'structured_light'
using_task_library 'offshore_pipeline_detector'
using_task_library 'buoy'
using_task_library 'frame_demultiplexer'
using_task_library 'controldev'
using_task_library 'raw_control_command_converter'
using_task_library 'motion_estimation'
using_task_library 'sonar_tritech'
using_task_library 'wall_servoing'
using_task_library 'sonar_feature_estimator'
using_task_library 'uwv_dynamic_model'
using_task_library 'sonar_wall_hough'
using_task_library 'uw_particle_localization'
using_task_library 'asv_detector'
using_task_library 'pingersearch'

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

composition 'OrientationWithZ' do
    add DepthReader::DepthAndOrientationFusion, :as => 'fusion'
    add Srv::Orientation
    add Srv::ZProvider

    connect orientation => fusion.orientation_samples
    connect z_provider => fusion.depth_samples

    export fusion.pose_samples
    provides Srv::OrientationWithZ
    provides Srv::Speed
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
    provides Srv::Speed
end

composition "DagonOrientationEstimator" do
    add OrientationEstimator::BaseEstimator, :as => 'estimator'

    add XsensImu::Task, :as => 'imu'
    add FogKvh::Dsp3000Task, :as => 'fog'

    connect imu => estimator.imu_orientation
    connect fog => estimator.fog_samples

    export estimator.attitude_b_g, :as => 'orientation_samples'
    provides Srv::Orientation
end


composition 'StructuredLight' do
    add Srv::StructuredLightPair
    add StructuredLight::Task, :as => 'structuredLight'

    export structuredLight.laser_scan
    provides Srv::LaserScanProvider
    autoconnect
end


#composition 'PipelineSonarDetector' do
#    add Srv::OrientationWithZ
#    add SonarTritech::Profiling
#    add Srv::Actuators
#    add Srv::RawCommand#, :as => 'rawCommand'  #needed only for debugging
#    add_main PiplineTracker::Task, :as => 'detector'
#   # add PiplineTracker::Task, :as => "detector"
#    autoconnect
#    export detector.position_command
#    provides Srv::RelativePositionDetector
#end

composition 'PipelineDetector' do
    event :check_candidate
    event :follow_pipe
    event :found_pipe
    event :align_auv
    event :lost_pipe
    event :search_pipe
    event :end_of_pipe
    event :weak_signal

    add Srv::ImageProvider, :as => 'camera'
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
        control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first

        if control_task
            #pid = control_task.orogen_task.controller_y
            #pid.Ti = 0.001
            #control_task.orogen_task.controller_y = pid
        end
    end

    on :stop do |event|
        Robot.info "resetting configuration"
        control_task = Roby.plan.find_tasks(Orocos::RobyPlugin::AuvRelPosController::Task).to_a.first

        if control_task
            #pid = control_task.orogen_task.controller_y
            #pid.Ti = 0
            #control_task.orogen_task.controller_y = pid
        end
    end
end

Cmp::VisualServoing.specialize 'detector' => Cmp::PipelineDetector do
    overload 'detector', Cmp::PipelineDetector,
        :success => :end_of_pipe,
        :remove_when_done => false
end

composition 'BuoyDetector' do
    event :buoy_search
    event :buoy_detected
    event :buoy_lost
    event :buoy_arrived
    event :strafing
    event :strafe_finished
    event :strafe_error
    event :moving_to_cutting_distance
    event :cutting
    event :cutting_success
    event :cutting_error

    add Srv::ImageProvider, :as => 'camera'
    add Srv::OrientationWithZ    
    #add_main Buoydetector::Task, :as => 'servoing'
    add_main Buoy::Detector, :as => 'detector'
    add Buoy::Survey, :as => 'servoing'
    add ModemCan::Task, :as => 'modem'

    connect camera => detector
    connect orientation_with_z => servoing
    connect servoing => modem
    connect detector => modem
    connect modem => servoing

    export servoing.relative_position
    provides Srv::RelativePositionDetector
end

#composition 'BuoyDetector' do
#    event :buoy_search
#    event :buoy_detected
#    event :buoy_lost
#    event :buoy_arrived
#    event :strafing
#    event :strafe_finished
#    event :strafe_error
#    event :moving_to_cutting_distance
#    event :cutting
#    event :cutting_success
#    event :cutting_error
#
#    add Srv::ImageProvider, :as => 'camera'
#    add Srv::OrientationWithZ    
#    add_main Buoydetector::Task, :as => 'servoing'
#    autoconnect
#
#    export servoing.relative_position
#    provides Srv::RelativePositionDetector
#end


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
    event :wall_servoing
    event :searching_wall
    event :checking_wall
    event :detected_corner
    event :lost_wall
    event :origin_alignment
    event :alignment_complete
    event :misconfiguration

    add Srv::SonarScanProvider, :as => 'sonar'
    add SonarFeatureEstimator::Task, :as => 'laserscan'
    add Srv::Orientation
    add_main WallServoing::SingleSonarServoing , :as => 'servoing'
    autoconnect

    export servoing.position_command, :as => 'relative_position_command'
    provides Srv::RelativePositionDetector
end

composition 'DualSonarWallDetector' do
    event :wall_servoing
    event :searching_wall
    event :detected_corner
    event :misconfiguration

#    add(SonarTritech::Micron, :as => 'sonar_front')
#    add(SonarTritech::Micron, :as => 'sonar_rear')
    add(Srv::SonarScanProvider, :as => 'sonar_front')
    add(Srv::SonarScanProvider, :as => 'sonar_rear')

    add(SonarFeatureEstimator::Task, :as => 'laserscan_front')
    add(SonarFeatureEstimator::Task, :as => 'laserscan_rear')

    add Srv::Orientation
    add_main WallServoing::DualSonarServoing , :as => 'servoing'
    connect sonar_front.sonarscan => laserscan_front.sonar_input
    connect sonar_rear.sonarscan => laserscan_rear.sonar_input
    connect laserscan_front.new_feature => servoing.sonarbeam_feature_front
    connect laserscan_rear.new_feature => servoing.sonarbeam_feature_rear
    autoconnect

    export servoing.position_command, :as => 'relative_position_command'
    provides Srv::RelativePositionDetector
end

composition 'AsvDetector' do
    event :asv_follow
    event :asv_lost_or_init
    event :asv_found
    event :searching
    event :surfacing
    event :asv_validate

    add Srv::ImageProvider, :as => 'camera_left'
    add Srv::ImageProvider, :as => 'camera_right'

    add Srv::OrientationWithZ, :as => 'orientation'
    add_main AsvDetector::Task, :as => 'detector'

    connect orientation.orientation_z_samples => detector.orientation_readings
    connect camera_left.images => detector.left_image
    
    export detector.position_command
    provides Srv::RelativePositionDetector
end

Cmp::VisualServoing.specialize 'detector' => Cmp::AsvDetector do
end


composition 'MotionEstimation' do
    add Srv::Actuators
    add Srv::OrientationWithZ
    add MotionEstimation::Task, :as => "motion"
    export motion.speed_samples
    autoconnect
    provides Srv::Speed
end

composition 'UwvModel' do
    #add AvalonControl::MotionControlTask, :as => 'motion_control'
    add Srv::OrientationWithZ
    add Srv::Actuators
    #add Srv::ActuatorController
    add UwvDynamicModel::Task, :as => 'model'
    autoconnect

    export model.uwvstate
    provides Srv::Speed
    provides Srv::RelativePose
end

composition 'SonarWallHough' do
    add Srv::OrientationWithZ
    add Srv::SonarScanProvider, :as => 'sonar'
    add SonarWallHough::Task, :as => 'hough'
    autoconnect

    export hough.position

    provides Srv::Pose
end

composition 'Localization' do
    add UwParticleLocalization::Task, :as => 'localization'
    add Srv::SonarScanProvider, :as => 'sonar'
    add SonarFeatureEstimator::Task, :as => 'feature_estimator'
    add Srv::OrientationWithZ, :as => 'orientation_with_z'
    add Srv::Speed, :as => 'model'
    add Srv::Actuators, :as => 'actuators'
    connect sonar => feature_estimator
    connect feature_estimator => localization
    connect orientation_with_z => feature_estimator
    connect orientation_with_z => localization.orientation_samples
    # connect model.speed_samples => localization.speed_samples
    connect actuators => localization

    export localization.pose_samples

    provides Srv::Pose
end

composition 'DualLocalization' do
    add UwParticleLocalization::Task, :as => 'localization'
    add SonarWallHough::Task, :as => 'hough'
    add Srv::SonarScanProvider, :as => 'sonar'
    add SonarFeatureEstimator::Task, :as => 'feature_estimator'
    add Srv::OrientationWithZ, :as => 'orientation_with_z'
    #add Cmp::UwvModel, :as => 'model'
    #add AvalonSimulation::StateEstimator, :as => 'model'
    add Srv::Speed, :as => 'model'
    connect sonar => feature_estimator
    connect sonar => hough
    connect feature_estimator => localization
    connect orientation_with_z => feature_estimator
    connect orientation_with_z => localization.orientation_samples
    connect orientation_with_z => hough
    connect model.speed_samples => localization.speed_samples

    export localization.pose_samples

    provides Srv::Pose
end

composition 'Pingersearch' do
    # Can be used in simulation as well since simulation omits audio capturing.
    add Srv::SoundSourceDirection, :as => 'angle_estimation'
    add Pingersearch::PingerSearch, :as => 'pingersearch' 
    autoconnect

    export pingersearch.position_command
    provides Srv::RelativePositionDetector
end

Cmp::Pingersearch.specialize 'angle_estimation' => Pingersearch::AngleEstimation do
    # On AVALON, use audio reader for sound capturing
    add AudioReader::Task, :as => 'audio_reader'
    autoconnect
end

Cmp::VisualServoing.specialize 'detector' => Cmp::Pingersearch do

end
