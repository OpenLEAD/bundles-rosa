require 'eigen'

# Mounting angle between the PTU's tilt plate and the mounting bracket
TILT_PLATE_TO_MOUNTING_BRACKET_ANGLE = - Math::PI / 4

dynamic_transform 'pressure.depth_samples',
    'surface' => 'body_horizontal'
dynamic_transform 'inclination_body.roll_samples',
    'body' => 'body_horizontal'

# The PTU is mounted upside down
static_transform Eigen::Vector3.new(0, 0, -1),
    'ptu_pan_plate' => 'body'

dynamic_transform 'ptu.transformation_samples',
    'ptu_tilt_plate' => 'ptu_pan_plate'

# Transformation that accounts for the mounting angle between the mounting
# bracket and the PTU's tilt plate
static_transform Eigen::Vector3.new(-0.103, 0, 0.078),
    'ptu_mounting_bracket_plate' => 'ptu_tilt_plate'

static_transform Eigen::Vector3.new(-0.045, -0.105, 0), Eigen::Quaternion.from_angle_axis(-Math::PI / 2, Eigen::Vector3.UnitY) * Eigen::Quaternion.from_angle_axis(-Math::PI / 2, Eigen::Vector3.UnitZ),
    'seaking_transducer' => 'ptu_mounting_bracket_plate'

