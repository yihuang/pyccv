import sys
from ccv import PY_CCV_IO_GRAY, DenseMatrix, ClassifierCascade, detect_objects

matrix = DenseMatrix()

#from PIL import Image
#img = Image.open(sys.argv[1])
#matrix.set_buf(img.tostring(), img.mode, img.size[0], img.size[1], PY_CCV_IO_GRAY)
matrix.set_file(sys.argv[1], PY_CCV_IO_GRAY)

cascade = ClassifierCascade()
cascade.read(sys.argv[2])

print detect_objects(matrix, cascade, 1)
