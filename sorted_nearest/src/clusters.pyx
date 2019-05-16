
from libc.stdint cimport int32_t

cimport cython

import numpy as np

def find_clusters(starts, ends, slack):

    if starts.dtype == np.long:
        return find_clusters64(starts, ends, slack)
    elif starts.dtype == np.int32:
        return find_clusters32(starts, ends, slack)
    else:
        raise Exception("Starts/Ends not int64 or int32: " + str(starts.dtype))


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.initializedcheck(False)
cpdef find_clusters64(long [::1] starts, long [::1] ends, int slack):

    cpdef int min_start = starts[0]
    cpdef int max_end = ends[0]
    cpdef int i = 0
    cpdef int n_clusters = 0
    cpdef int length = len(starts)

    output_arr_start = np.ones(length, dtype=np.long) * -1
    output_arr_end = np.zeros(length, dtype=np.long) * -1

    cdef long [::1] output_start
    cdef long [::1] output_end

    output_start = output_arr_start
    output_end = output_arr_end

    for i in range(length):
        if not (starts[i] - slack) <= max_end:
            output_start[n_clusters] = min_start
            output_end[n_clusters] = max_end
            min_start = starts[i]
            max_end = ends[i]
            n_clusters += 1
        else:
            if ends[i] > max_end:
                max_end = ends[i]

    if output_arr_start[n_clusters] != min_start:
        output_arr_start[n_clusters] = min_start
        output_arr_end[n_clusters] = max_end
        n_clusters += 1

    return output_arr_start[:n_clusters], output_arr_end[:n_clusters]


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.initializedcheck(False)
cpdef find_clusters32(int32_t [::1] starts, int32_t [::1] ends, int slack):

    cpdef int min_start = starts[0]
    cpdef int max_end = ends[0]
    cpdef int i = 0
    cpdef int n_clusters = 0
    cpdef int length = len(starts)

    output_arr_start = np.ones(length, dtype=np.int32) * -1
    output_arr_end = np.zeros(length, dtype=np.int32) * -1

    cdef int32_t [::1] output_start
    cdef int32_t [::1] output_end

    output_start = output_arr_start
    output_end = output_arr_end

    for i in range(length):
        if not (starts[i] - slack) <= max_end:
            output_start[n_clusters] = min_start
            output_end[n_clusters] = max_end
            min_start = starts[i]
            max_end = ends[i]
            n_clusters += 1
        else:
            if ends[i] > max_end:
                max_end = ends[i]

    if output_arr_start[n_clusters] != min_start:
        output_arr_start[n_clusters] = min_start
        output_arr_end[n_clusters] = max_end
        n_clusters += 1

    return output_arr_start[:n_clusters], output_arr_end[:n_clusters]
