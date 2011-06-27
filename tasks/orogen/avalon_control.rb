class AvalonControl::MotionControlTask 
    provides Srv::AUVMotionController
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::MotionControlTask do
    add Srv::OrientationWithZ, :as => 'pose'
    connect pose.orientation_z_samples => controller.pose_samples
end

Cmp::ControlLoop.specialize 'controller' => AvalonControl::PositionControlTask do
    add Srv::Pose
    autoconnect
end

