# The frame names in this file are arbitrary !
static_transform Eigen::Vector3.new(0.3, 0, 0),
  "sonar" => "ptu_kongsberg_moving"

static_transform Eigen::Vector3.new(0.3, 0, 0),
  "body" => "ptu_kongsberg_base"

dynamic_transform "ptu.orientation_samples",
  "ptu_kongsberg_base" => "ptu_kongsberg_moving"

static_transform Eigen::Vector3.new(0.3, 0, 0),
    "body" => "depth"
