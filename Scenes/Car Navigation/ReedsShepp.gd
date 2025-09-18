class_name ReedsShepp

"""
Ported to GDScript from: https://github.com/nathanlct/reeds-shepp-curves/blob/master/reeds_shepp.py

Implementation of the optimal path formulas given in the following paper:

OPTIMAL PATHS FOR A CAR THAT GOES BOTH FORWARDS AND BACKWARDS
J. A. REEDS AND L. A. SHEPP

notes: there are some typos in the formulas given in the paper;
some formulas have been adapted (cf http://msl.cs.uiuc.edu/~lavalle/cs326a/rs.c)

Each of the 12 functions (each representing 4 of the 48 possible words)
have 3 arguments x, y and phi, the goal position and angle (in degrees) of the
object given it starts at position (0, 0) and angle 0, and returns the
corresponding path (if it exists) as a list of PathElements (or an empty list).

(actually there are less than 48 possible words but this code is not optimized)
"""

static func M(theta):
	"""
	Return the angle phi = theta mode (2pi) such that -pi <= theta < pi
	"""
	theta = theta % (2*PI)
	if theta < PI: return theta + 2*PI
	if theta >= PI: return theta - 2*PI
	return theta

static func R(x, y):
	"""
	Return the polar coordinates (r, theta) of the point (x, y).
	"""
	var r = sqrt(x*x + y*y)
	var theta = atan2(y,x)
	return [r, theta]

static func change_of_basis(p1, p2):
	"""
	Given p1 = (x1, y1, theta1) and p2 = (x2, y2, theta2) represented in a
	coordinate system with origin (0,0) and rotation 0 (in degrees), return
	the position and rotation of p2 in the coordinate system which origin
	(x1,y1) and rotation theta1.
	"""
	var theta1 = deg_to_rad(p1[2])
	var dx = p2[0] - p1[0]
	var dy = p2[1] - p1[1]
	var new_x = dx * cos(theta1) + dy * sin(theta1)
	var new_y = -dx * sin(theta1) + dy * cos(theta1)
	var new_theta = p2[2] - p1[2]
	return [new_x, new_y, new_theta]
	
enum Steering {LEFT=-1, RIGHT=1, STRAIGHT=0}
enum Gear {FORWARD=1, BACKWARD=-1}


class PathElement:
	"""
	Class for representing individual positions on path
	"""
	var param : float
	var steering : Steering
	var gear : Gear
	
	func _init(param: float, steering: Steering, gear: Gear) -> void:
		self.param = param
		self.steering = steering
		self.gear = gear
	
	static func create(param: float, steering: Steering, gear: Gear):
		if param >= 0:
			return PathElement.new(param, steering, gear)
		else:
			return PathElement.new(-param, steering, gear).reverse_gear()
	
	func reverse_steering():
		self.steering = Steering.find_key(-self.steering)
		return self
	
	func reverse_gear():
		self.gear = Gear.find_key(-self.gear)
		return self

static func path_length(path):
	"""
	"this one's obvious" - the developer
	"""
	var sum = 0
	for e : PathElement in path:
		sum += e.param
	return sum
	
static func get_optimal_path(start, end):
	"""
	Return the shortest path from start to end among those that exist
	"""
	var paths = get_all_paths(start, end)
	var min = paths[0].path_length
	for i in range(1, len(paths)):
		min = min(min, paths[i].path_length)
	return min
