var name
var points
var radians
var vector
var Infinity = 88888888888888

func _init(m_name, m_points):
	name = m_name
	points = Resample(m_points, 128)
	radians = IndicativeAngle(points)
	#points = RotateBy(points, -radians)
	points = ScaleTo(points, 250.0)
	points = TranslateTo(points, Vector2(0,0))
	vector = Vectorize(points)

func Resample(points, n):
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

func Centroid(points):
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