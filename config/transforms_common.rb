## Static transforms of avalon ##

#FIXME add the real transformation
## sonar pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.5, 0.0, 0.05 ),
    "sonar" => "body"

## angle of the wall in the world frame
static_transform Eigen::Quaternion.from_angle_axis( 0.0 / 180.0 * Math::PI, Eigen::Vector3.UnitZ ),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "wall" => "world"
