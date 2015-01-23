require 'eigen'

# Mounting angle between the PTU's tilt plate and the mounting bracket
TILT_PLATE_TO_MOUNTING_BRACKET_ANGLE = - Math::PI / 4

dynamic_transform 'pressure.depth_samples',
    'surface' => 'world_inclinometer_roll'
dynamic_transform 'inclination_body.roll_samples',
    'inclinometer_roll' => 'world_inclinometer_roll'

#Static transformation for the inclinomenter be a pitch
static_transform Eigen::Quaternion.from_angle_axis(Math::PI / 2, Eigen::Vector3.UnitZ),
    'world_inclinometer_pitch' => 'inclinometer_roll'

dynamic_transform 'inclination_body_2.roll_samples',
    'inclinometer_pitch' => 'world_inclinometer_pitch'

#Back to the body frame
static_transform Eigen::Quaternion.from_angle_axis(-Math::PI / 2, Eigen::Vector3.UnitZ),
    'body' => 'inclinometer_pitch'
    
## The PTU is mounted upside down
static_transform Eigen::Vector3.new(0, 0, 1),
    'body' => 'ptu_tilt_plate'

dynamic_transform 'ptu.transformation_samples',
    'ptu_tilt_plate' => 'ptu_pan_plate'

# Transformation that accounts for the mounting angle between the mounting
# bracket and the PTU's tilt plate
static_transform Eigen::Vector3.new(-0.103, 0, 0.078),
    'ptu_mounting_bracket_plate' => 'ptu_pan_plate'

static_transform Eigen::Vector3.new(-0.045, -0.105, 0), Eigen::Quaternion.from_angle_axis(Math::PI / 2, Eigen::Vector3.UnitX) * Eigen::Quaternion.from_angle_axis(Math::PI, Eigen::Vector3.UnitZ),
    'seaking_transducer' => 'ptu_mounting_bracket_plate'

