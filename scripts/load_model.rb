require 'rock/bundles'
require 'orocos'
require 'readline'
#library for displaying data
require 'vizkit'


include Bundles
Bundles.initialize
## Create a widget for 3d display
view3d = Vizkit.vizkit3d_widget

lifiting_beam = Vizkit.default_loader.RigidBodyStateVisualization
lifiting_beam.loadModel('VigaPescadora_Tris.wrl')
#lifiting_beam.loadModel('antique_brass(1).ply')
lifting_start_angle = Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitY)*Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitZ)*Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitX)
lifiting_beam.rotateModel(lifting_start_angle.to_qt)
lifiting_beam.setScale(0.0106)

ptu = Vizkit.default_loader.RigidBodyStateVisualization
ptu.loadModel('ptu_aluminium.wrl')

sonar = Vizkit.default_loader.RigidBodyStateVisualization
sonar.loadModel('seaking.wrl')

view3d.setPluginDataFrame('body',lifiting_beam)
view3d.setPluginDataFrame('ptu_pan_plate',ptu)
view3d.setPluginDataFrame('seaking_transducer',sonar)

# Show it
view3d.show
# And listen to GUI events
Vizkit.exec
