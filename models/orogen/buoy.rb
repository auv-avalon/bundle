
class Buoy::Survey
    #TODO nothing?
end

class Buoy::Detector
    #TODO nothing?
end


class BuoyDetector < Syskit::Composition
    event :buoy_search
    event :buoy_detected
    event :buoy_arrived
    event :buoy_lost
    event :strafing
    event :strafe_finished
    event :strafe_to_angle
    event :angle_arrived
#    event :strafe_error
#    event :moving_to_cutting_distance
#    event :cutting
#    event :cutting_success
#    event :cutting_error
    event :timeout

    add Base::ImageProviderSrv, :as => 'camera'
    add Base::OrientationWithZSrv, :as => "orienation_with_z"
    add Buoy::Detector, :as => 'detector'
    add_main Buoy::Survey, :as => 'servoing'
    #TODO Reintegrate modem
    #add Srv::ModemConnection, :as => 'modem'
    #connect detector => modem
    #connect modem => servoing

    camera_child.frame_port.connect_to  detector_child
    orienation_with_z_child.connect_to  servoing_child
    detector_child.light_port.connect_to servoing_child.light_port
    detector_child.buoy_port.connect_to servoing_child.input_buoy_port
   
    export servoing_child.relative_position_port, :as => 'relative_position_command'
    provides Base::AUVRelativeMotionControllerSrv, :as => 'controller'
end

