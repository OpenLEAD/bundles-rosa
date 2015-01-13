# Mounting angle between the PTU's tilt plate and the mounting bracket
TILT_PLATE_TO_MOUNTING_BRACKET_ANGLE = 0

# The PTU is mounted upside down
static_transform Eigen::Quaterniond.from_angle_axis(Math::PI, Eigen::Vector3d::UnitX),
    'body' => 'ptu_pan_plate'

dynamic_transform 'ptu.transformation_samples',
    'ptu_pan_plate' => 'ptu_tilt_plate'

# Transformation that accounts for the mounting angle between the mounting
# bracket and the PTU's tilt plate
static_transform Eigen::Quaterniond.from_angle_axis(TILT_PLATE_TO_MOUNTING_BRACKET_ANGLE, Eigen::Vector3::UnitZ),
    'ptu_tilt_plate' => 'ptu_mounting_bracket_axis'

static_transform Eigen::Vector3.new(0, -0.103, -0.078), Eigen::Quaterniond.from_angle_axis(Math::PI/2, Eigen::Vector3::UnitX),
    'ptu_mounting_bracket_axis' => 'ptu_mounting_bracket_plate'

static_transform Eigen::Vector3.new(0.5, 0.2, 0), Eigen::Quaterniond.from_angle_axis(Math::PI/2, Eigen::Vector3::UnitY),
    'ptu_mounting_bracket_plate' => 'seaking_transducer'

