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
lifiting_beam.loadModel('viga_pescadora3.wrl')
#lifiting_beam.loadModel('antique_brass(1).ply')
lifting_start_angle = Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitY)*Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitZ)*Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitX)
lifiting_beam.rotateModel(lifting_start_angle.to_qt)
lifiting_beam.setScale(1)

#dam = Vizkit.default_loader.RigidBodyStateVisualization
#dam.loadModel('dam.3ds')
#dam.setScale(1)

#bottom_profile = Vizkit.default_loader.EnvireVisualization
#bottom_profile.load('mls-merged-scans')

ptu = Vizkit.default_loader.RigidBodyStateVisualization
ptu.loadModel('ptu_aluminium.wrl')
 
sonar = Vizkit.default_loader.RigidBodyStateVisualization
sonar.loadModel('seaking.wrl')

view3d.setPluginDataFrame('body',lifiting_beam)
#view3d.setPluginDataFrame('reference', bottom_profile)
#view3d.setPluginDataFrame('surface', dam)
view3d.setPluginDataFrame('ptu_pan_plate',ptu)
view3d.setPluginDataFrame('seaking_transducer',sonar)

# Show it
view3d.show
# And listen to GUI events
Vizkit.exec
