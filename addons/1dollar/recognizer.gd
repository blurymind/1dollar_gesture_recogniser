var point = Vector2()

var NumPoints = 128
var SquareSize = 250.0
var Origin = Vector2(0,0)
var Diagonal = sqrt(SquareSize * SquareSize + SquareSize * SquareSize)
var HalfDiagonal = 0.5 * Diagonal
var AngleRange = deg2rad(45.0)
var AnglePrecision = deg2rad(2.0)
var Phi = 0.5 * (-1.0 + sqrt(5.0))
var Infinity = 88888888888888

var unistroke_triangle = preload("unistroke.gd").new("triangle",[Vector2(137,139),Vector2(135,141),Vector2(133,144),Vector2(132,146),Vector2(130,149),Vector2(128,151),Vector2(126,155),Vector2(123,160),Vector2(120,166),Vector2(116,171),Vector2(112,177),Vector2(107,183),Vector2(102,188),Vector2(100,191),Vector2(95,195),Vector2(90,199),Vector2(86,203),Vector2(82,206),Vector2(80,209),Vector2(75,213),Vector2(73,213),Vector2(70,216),Vector2(67,219),Vector2(64,221),Vector2(61,223),Vector2(60,225),Vector2(62,226),Vector2(65,225),Vector2(67,226),Vector2(74,226),Vector2(77,227),Vector2(85,229),Vector2(91,230),Vector2(99,231),Vector2(108,232),Vector2(116,233),Vector2(125,233),Vector2(134,234),Vector2(145,233),Vector2(153,232),Vector2(160,233),Vector2(170,234),Vector2(177,235),Vector2(179,236),Vector2(186,237),Vector2(193,238),Vector2(198,239),Vector2(200,237),Vector2(202,239),Vector2(204,238),Vector2(206,234),Vector2(205,230),Vector2(202,222),Vector2(197,216),Vector2(192,207),Vector2(186,198),Vector2(179,189),Vector2(174,183),Vector2(170,178),Vector2(164,171),Vector2(161,168),Vector2(154,160),Vector2(148,155),Vector2(143,150),Vector2(138,148),Vector2(136,148)])

var Unistrokes = []
#var Unistrokes = [
#	unistroke_triangle
#	]

func recognize(points):
	points = Resample(points, NumPoints)
	var radians = IndicativeAngle(points)
	#points = RotateBy(points, -radians)
	points = ScaleTo(points, SquareSize)
	points = TranslateTo(points, Origin)
	var vector = Vectorize(points) #for Protractor
	var b = Infinity #Magic number :)
	var u = -1
	for i in range(Unistrokes.size()): #for each unistroke
		#var d = OptimalCosineDistance(Unistrokes[i].vector, vector)
		var d = DistanceAtBestAngle(points, Unistrokes[i], -AngleRange, AngleRange, AnglePrecision)
		if (d < b):
			b = d # best (least) distance
			u = i # unistroke
	if (u == -1):
		return ["no match", 0.0]
	else:
		#return [Unistrokes[u].name, 1.0/b]
		return [Unistrokes[u].name, 1.0 - b / HalfDiagonal]
#   return (u == -1) ? new Result("No match.", 0.0) : new Result(this.Unistrokes[u].Name, useProtractor ? 1.0 / b : 1.0 - b / HalfDiagonal);
func addGesture(name, points):
	Unistrokes.append(preload("unistroke.gd").new(name, points)) # append new unistroke

func Resample(points, n):
	if points.size() == 0:return
	var I = PathLength(points)/(n - 1) # interval length
	var D = 0.0
	var newpoints = [points[0]]
	#for i in range(points.size()):
	var i = 1
	while (i < points.size()):
		#var d = Distance(points[i - 1], points[i])
		var d = points[i-1].distance_to(points[i])
		if ((D + d) >= I):
			var qx = points[i - 1].x + ((I - D) / d) * (points[i].x - points[i - 1].x)
			var qy = points[i - 1].y + ((I - D) / d) * (points[i].y - points[i - 1].y)
			var q = Vector2(qx, qy)
			newpoints.append(q)
			#newpoints[newpoints.size()] = q # append new point 'q'
			points.insert(i, q) # insert 'q' at position i in points s.t. 'q' will be the next i
			D = 0.0
		else: D += d
		i += 1
	if (newpoints.size() == n - 1): # somtimes we fall a rounding-error short of adding the last point, so add it if so
		newpoints.append(points[points.size() - 1])
	return newpoints

func IndicativeAngle(points):
	var c = Centroid(points)
	return atan2(c.y - points[0].y, c.x - points[0].x)

func RotateBy(points, radians): # rotates points around centroid
	var c = Centroid(points)
	var mcos = cos(radians)
	var msin = sin(radians)
	var newpoints = Vector2Array()
	for i in range(points.size()):
		var qx = (points[i].x - c.x) * mcos - (points[i].x - c.x) * msin + c.x
		var qy = (points[i].x - c.x) * msin + (points[i].x - c.x) * mcos + c.x
		newpoints.append(Vector2(qx, qy))
	return newpoints

func ScaleTo(points, size): # non-uniform scale; assumes 2D gestures (i.e., no lines)
	var B = BoundingBox(points)
	var newpoints = Vector2Array()
	for i in range(points.size()):
		var qx = points[i].x * (size / B.width)
		var qy = points[i].y * (size / B.height)
		newpoints.append(Vector2(qx, qy))
	return newpoints

func TranslateTo(points, pt): # translates points' centroid
	var c = Centroid(points)
	var newpoints = Vector2Array()
	for i in range(points.size()):
		var qx = points[i].x + pt.x - c.x
		var qy = points[i].y + pt.y - c.y
		newpoints.append(Vector2(qx, qy))
	return newpoints

func Vectorize(points): # for Protractor
	var sum = 0.0
	var vector = []
	for i in range(points.size()):
		vector.append(points[i].x)
		vector.append(points[i].y)
		sum += points[i].x * points[i].x + points[i].y * points[i].y
	var magnitude = sqrt(sum)
	for i in range(vector.size()):
		vector[i] /= magnitude
	return vector

func OptimalCosineDistance(v1, v2): # for Protractor
	var a = 0.0;
	var b = 0.0;
	for i in range(0,v1.size(),2):
		a += v1[i] * v2[i] + v1[i + 1] * v2[i + 1]
		b += v1[i] * v2[i + 1] - v1[i + 1] * v2[i]
	var angle = atan(b / a)
	return acos(a * cos(angle) + b * sin(angle))

func DistanceAtBestAngle(points, T, a, b, threshold):
	var x1 = Phi * a + (1.0 - Phi) * b
	var f1 = DistanceAtAngle(points, T, x1)
	var x2 = (1.0 - Phi) * a + Phi * b
	var f2 = DistanceAtAngle(points, T, x2)
	while (abs(b - a) > threshold):
		if (f1 < f2):
			b = x2
			x2 = x1
			f2 = f1
			x1 = Phi * a + (1.0 - Phi) * b
			f1 = DistanceAtAngle(points, T, x1) 
		else:
			a = x1;
			x1 = x2;
			f1 = f2;
			x2 = (1.0 - Phi) * a + Phi * b;
			f2 = DistanceAtAngle(points, T, x2);
	return min(f1, f2);

func DistanceAtAngle(points, T, radians):
	#var newpoints = RotateBy(points, radians); 
	#return PathDistance(newpoints, T.points);
	return PathDistance(points, T.points);

func Centroid(points):
	if points == null :return
	var x = 0.0
	var y = 0.0
	for i in range(points.size()):
		x += points[i].x
		y += points[i].y
	x /= points.size()
	y /= points.size()
	return Vector2(x, y)

func BoundingBox(points):
	var minX = Infinity
	var maxX = -Infinity
	var minY = Infinity
	var maxY = -Infinity
	for i in range(points.size()):
		minX = min(minX, points[i].x)
		minY = min(minY, points[i].y)
		maxX = max(maxX, points[i].x)
		maxY = max(maxY, points[i].y)
	return preload("rectangle.gd").new(minX, minY, maxX - minX, maxY - minY)

func PathDistance(pts1, pts2):
	var d = 0.0
	#pts2.resize(pts1.size())
	for i in range(pts1.size()): # assumes pts1.length == pts2.length
		#d += Distance(pts1[i], pts2[i])
		d += pts1[i].distance_to(pts2[i])
	return d / pts1.size()
           
func PathLength(points):        
	var d = 0.0 
	#for i in range(points.size()): 
	var i = 1
	var points_size = points.size()
	while (i < points_size):
		#d += Distance(points[i - 1], points[i])
		d += points[i - 1].distance_to(points[i])
		i += 1
	return d 
           
func Distance(p1, p2):
	var dx = p2.x - p1.x
	var dy = p2.y - p1.y
	return sqrt(dx * dx + dy * dy)