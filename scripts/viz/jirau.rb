require 'vizkit'
require 'rock/bundles'

Bundles.load

vizkit3d = Vizkit.vizkit3d_widget
vizkit3d.show

model = Vizkit.default_loader.RigidBodyStateVisualization
model.loadModel Bundles.find_file('data', 'models', 'jirau.osgt')
model.setTranslation(Qt::Vector3D.new(0, 105, -30))
model.setRotation(Eigen::Quaternion.from_angle_axis(-Math::PI/2, Eigen::Vector3.UnitZ).to_qt)
model.setTexture Bundles.find_file('data', 'textures', 'concrete', 'concrete.jpg')
model.addBumpMapping Bundles.find_file('data', 'textures', 'concrete', 'concrete_d.jpg'),
    Bundles.find_file('data', 'textures', 'concrete', 'concrete_n.jpg')

view3d = Vizkit.vizkit3d_widget
ocean = Vizkit.default_loader.Ocean
view3d.setEnvironmentPlugin(ocean)

Vizkit.exec
