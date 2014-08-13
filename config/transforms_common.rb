## Static transforms of avalon ##

### Sensors

#FIXME add the real transformation
## sonar pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.5, 0.0, 0.05 ),
    "sonar" => "body"

#FIXME add the real transformation
## echosounder pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( -0.7, 0.0, -0.15 ),
    "echosounder" => "body"

#FIXME add the real transformation
## gps receiver pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "gps_receiver" => "body"

#FIXME add the real transformation
## pressure sensor in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "pressure_sensor" => "body"

#FIXME add the real transformation
## front camera in body frame
static_transform Eigen::Quaternion.from_angle_axis( 10.0 / 180.0 * Math::PI, Eigen::Vector3.UnitY ),
    Eigen::Vector3.new( 0.7, 0.0, 0.0 ),
    "front_camera" => "body"

#FIXME add the real transformation
## bottom camera in body frame
static_transform Eigen::Quaternion.from_angle_axis( 90.0 / 180.0 * Math::PI, Eigen::Vector3.UnitY ),
    Eigen::Vector3.new( 0.7, 0.0, -0.1 ),
    "bottom_camera" => "body"

#FIXME add the real transformation
## imu pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "imu" => "body"

#FIXME add the real transformation
## imu pose in body frame
static_transform Eigen::Quaternion.Identity,
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "fog" => "body"


### Misc

## angle of the reference wall in the world frame
## this is the angle of lower wall in the sauc-e basin, based on google earth gps coordinates
static_transform Eigen::Quaternion.from_angle_axis( 72.09528 / 180.0 * Math::PI, Eigen::Vector3.UnitZ ),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ),
    "reference_wall" => "world"
