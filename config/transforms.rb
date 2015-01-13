require 'eigen'

# Mounting angle between the PTU's tilt plate and the mounting bracket
TILT_PLATE_TO_MOUNTING_BRACKET_ANGLE = - Math::PI / 4

# The PTU is mounted upside down
static_transform Eigen::Vector3.new(0, 0, 1), Eigen::Quaternion.from_angle_axis(Math::PI, Eigen::Vector3.UnitX),
    'body' => 'ptu_pan_plate'

dynamic_transform 'ptu.transformation_samples',
    'ptu_pan_plate' => 'ptu_tilt_plate'

# Transformation that accounts for the mounting angle between the mounting
# bracket and the PTU's tilt plate
static_transform Eigen::Vector3.new(-0.103, 0, 0.078),
    'ptu_tilt_plate' => 'ptu_mounting_bracket_plate'

static_transform Eigen::Vector3.new(-0.045, -0.105, 0), Eigen::Quaternion.from_angle_axis(Math::PI, Eigen::Vector3.UnitZ) * Eigen::Quaternion.from_angle_axis(-Math::PI, Eigen::Vector3.UnitX),
    'ptu_mounting_bracket_plate' => 'seaking_transducer'

