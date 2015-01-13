static_transform Eigen::Quaterniond.from_angle_axis(Math::PI, Eigen::Vector3d::UnitX),
    'body' => 'ptu_pan_plate'

dynamic_transform 'ptu.transformation_samples',
    'ptu_pan_plate' => 'ptu_tilt_plate'

static_transform Eigen::Vector3.new(0, -0.5, -0.4), Eigen::Quaterniond.from_angle_axis(Math::PI/2, Eigen::Vector3::UnitX),
    'ptu_tilt_plate' => 'ptu_mounting_bracket'

static_transform Eigen::Vector3.new(.5, .2, 0), Eigen::Quaterniond.from_angle_axis(Math::PI/2, Eigen::Vector3::UnitY),
    'ptu_mounting_bracket' => 'seaking_transducer'

