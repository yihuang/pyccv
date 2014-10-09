import sys
from ccv import PY_CCV_IO_GRAY, DenseMatrix, ClassifierCascade, detect_objects

matrix = DenseMatrix()
matrix.set_file(sys.argv[1], PY_CCV_IO_GRAY)

cascade = ClassifierCascade()
cascade.read(sys.argv[2])

print detect_objects(matrix, cascade, 1)
