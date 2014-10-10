from libc.stdlib cimport malloc

cdef extern from "ccv.h":

    ctypedef struct ccv_dense_matrix_t
    void ccv_matrix_free(void* mat)
    int ccv_read_impl(const void* _in, ccv_dense_matrix_t** x, int type, int rows, int cols, int scanline)

    ctypedef struct ccv_bbf_classifier_cascade_t
    void ccv_bbf_classifier_cascade_free(ccv_bbf_classifier_cascade_t* cascade)
    ccv_bbf_classifier_cascade_t* ccv_bbf_read_classifier_cascade(const char* directory)
    int ccv_bbf_classifier_cascade_write_binary(ccv_bbf_classifier_cascade_t* cascade, char* s, int slen)
    ccv_bbf_classifier_cascade_t* ccv_bbf_classifier_cascade_read_binary(char* s)

    ctypedef struct ccv_array_t:
        int rnum

    void ccv_array_free(ccv_array_t* array)
    void* ccv_array_get(ccv_array_t* array, int i)

    ctypedef struct ccv_bbf_param_t:
        pass

    ccv_bbf_param_t ccv_bbf_default_params

    ccv_array_t* ccv_bbf_detect_objects(ccv_dense_matrix_t* a, ccv_bbf_classifier_cascade_t** _cascade, int count, ccv_bbf_param_t params)

    ctypedef struct ccv_rect_t:
        int x
        int y
        int width
        int height

    ctypedef struct ccv_classification_t:
        int id
        float confidence

    ctypedef struct ccv_comp_t:
        ccv_rect_t rect
        int neighbors
        ccv_classification_t classification

    enum:
        CCV_IO_RGB_RAW
        CCV_IO_RGBA_RAW
        CCV_IO_GRAY_RAW
        CCV_IO_ANY_FILE

        CCV_IO_GRAY
        CCV_IO_RGB_COLOR

PY_CCV_IO_GRAY = CCV_IO_GRAY
PY_CCV_IO_RGB_COLOR = CCV_IO_RGB_COLOR

cdef class DenseMatrix(object):
    cdef ccv_dense_matrix_t* _matrix

    def __dealloc__(self):
        self.clear()

    cpdef clear(self):
        if self._matrix != NULL:
            ccv_matrix_free(self._matrix)
            self._matrix = NULL

    def set_file(self, filename, int convert=0):
        self.clear()
        ccv_read_impl(<char*><bytes>filename, &self._matrix, convert | CCV_IO_ANY_FILE, 0, 0, 0)

    def set_buf(self, char[:] buf, mode, int rows, int cols, int convert=0):
        cdef int type = convert
        cdef int components = 0
        if mode == 'L':
            type |= CCV_IO_GRAY_RAW
            components = 1
        elif mode == 'RGB':
            type |= CCV_IO_RGB_RAW
            components = 3
        elif mode == 'RGBA':
            type |= CCV_IO_RGBA_RAW
            components = 4
        else:
            raise NotImplementedError('not supported mode %s' % mode)

        self.clear()
        ccv_read_impl(<char*>buf, &self._matrix, type, rows, cols, cols*components)

cdef class ClassifierCascade(object):
    cdef ccv_bbf_classifier_cascade_t* _cascade

    cpdef clear(self):
        if self._cascade != NULL:
            ccv_bbf_classifier_cascade_free(self._cascade)
            self._cascade = NULL

    def __dealloc__(self):
        self.clear()

    def read(self, directory):
        self.clear()
        self._cascade = ccv_bbf_read_classifier_cascade(<char*><bytes>directory)

    def read_binary(self, s):
        self.clear()
        self._cascade = ccv_bbf_classifier_cascade_read_binary(<char*><bytes>s)

    def write_binary(self):
        assert self._cascade != NULL, 'not initialized'
        cdef int size = ccv_bbf_classifier_cascade_write_binary(self._cascade, NULL, 0)
        cdef char* s = <char*>malloc(size)
        ccv_bbf_classifier_cascade_write_binary(self._cascade, s, size)
        cdef bytes result = s[:size]
        return result

def detect_objects(DenseMatrix matrix, ClassifierCascade cascade, count):
    assert matrix._matrix != NULL, 'not initialized matrix'
    assert cascade._cascade != NULL, 'not initialized cascade'
    cdef ccv_array_t* arr = ccv_bbf_detect_objects(matrix._matrix, &cascade._cascade, count, ccv_bbf_default_params)
    cdef int i=0
    cdef ccv_comp_t* comp
    result = []
    for i in range(arr.rnum):
        comp = <ccv_comp_t*>ccv_array_get(arr, i)
        result.append((
            (comp.rect.x, comp.rect.y, comp.rect.width, comp.rect.height),
            comp.classification.confidence,
        ))
    return result

def decodeYUV420SP(_in, int width, int height):
    cdef int frameSize = width * height
    cdef int i=0, j=0, yp=0
    cdef bytearray rgb_ba = bytearray(width*height*sizeof(int))
    cdef int* rgb = <int*><char*>rgb_ba
    cdef char[:] yuv420sp = _in[:]
    #cdef char* yuv420sp = tmp

    cdef int u, v, uvp
    cdef int y, y1192, r, g, b

    for j in range(height):
        u = 0
        v = 0
        uvp = frameSize + (j >> 1) * width
        for i in range(width):
            yp += 1
            y = (0xff & (<int>yuv420sp[yp])) - 16
            if y < 0:
                y = 0
            if (i & 1) == 0:
                v = (0xff & yuv420sp[uvp]) - 128
                uvp += 1
                u = (0xff & yuv420sp[uvp]) - 128
                uvp += 1

            y1192 = 1192 * y
            r = (y1192 + 1634 * v)
            g = (y1192 - 833 * v - 400 * u)
            b = (y1192 + 2066 * u)

            if r < 0:
                r = 0
            elif r > 262143:
                r = 262143

            if g < 0:
                g = 0
            elif g > 262143:
                g = 262143

            if b < 0:
                b = 0
            elif b > 262143:
                b = 262143

            rgb[yp] = 0xff000000 | ((r << 6) & 0xff0000) | ((g >> 2) & 0xff00) | ((b >> 10) & 0xff);  

    return rgb_ba
