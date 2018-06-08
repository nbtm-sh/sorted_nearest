cimport sorted_nearest.src.csorted_nearest as cn

cimport cython

import numpy as np


@cython.boundscheck(True)
@cython.wraparound(False)
cpdef nearest(long [::1] l_s, long [::1] l_e, long [::1] r_s, long [::1] r_e):

    cdef int _continue = 1
    cdef int min_diff = cn.INT_MAX
    cdef int new_diff = cn.INT_MAX
    cdef int min_j = -1
    cdef int j = 0
    cdef int inc_j = 0
    cdef int i = 0
    cdef int ZERO = 0
    cdef int length_l = len(l_s)
    cdef int length_r = len(r_s)
    cdef int length_r_minus_one = len(r_s) - 1

    output_arr_ridx = np.ones(length_l, dtype=np.long) * -1
    output_arr_dist = np.ones(length_l, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    while i < length_l and j < length_r:

        inc_j = 0
        #print("---" * 5)
        #print("i", i, "j", j)
        # overlap
        #print("l_s[i]", l_s[i])
        #print("l_e[i]", l_e[i])
        #print("r_s[j]", r_s[j])
        #print("r_e[j]", r_e[j])
        if (r_s[j] <= l_e[i] <= r_e[j]) or (r_s[j] <= l_s[i] <= r_e[j]) or (l_s[i] <= r_s[j] <= l_e[i]) or (l_s[i] <= r_e[j] <= l_e[i]):
            #print("overlap")
            #print("pushing", j, "diff", min_diff)
            output_ridx[i] = j
            output_dist[i] = 0
            i += 1
            min_diff = cn.INT_MAX

        elif l_e[i] <= r_s[j]:
            #print(i, "l_e[i] < r_s[j]", l_e[i], r_s[j])
            new_diff = r_s[j] - l_e[i]
            if new_diff < min_diff:
                min_diff = new_diff
                min_j = j
            inc_j = 1

        elif l_s[i] >= r_e[j]:
            #print(i, "l_s[i] > r_e[j]", l_s[i], r_e[j])
            new_diff = l_s[i] - r_e[j]
            if new_diff < min_diff:
                min_diff = new_diff
                min_j = j

            if new_diff > (l_s[i] - r_e[j]):
                #print("new_diff", new_diff, "dist", l_s[i] - r_e[j])
                #print("pushing", min_j, "diff", min_diff)
                output_ridx[i] = min_j
                output_dist[i] = min_diff
                i += 1
                j = min_j
                min_diff = cn.INT_MAX
            else:
                inc_j = 1

        if j == length_r_minus_one and i < length_l and output_ridx[i] == -1:
            #print("length j is max!")
            #print("min_diff", min_diff)
            #print("min_j", min_j)
            if (r_s[j] <= l_e[i] <= r_e[j]) or (r_s[j] <= l_s[i] <= r_e[j]) or (l_s[i] <= r_s[j] <= l_e[i]) or (l_s[i] <= r_e[j] <= l_e[i]):
                #print("overlap")
                new_diff = 0
                if new_diff < min_diff:
                    min_diff = new_diff
                    min_j = j
            elif l_s[i] > r_e[j]:
                #print("ls > re")
                new_diff = l_s[i] - r_e[j]
                #print("new_diff", new_diff)
                if new_diff < min_diff:
                    min_diff = new_diff
                    min_j = j
            elif l_e[i] < r_s[j]:
                #print("le < rs")
                new_diff = r_s[j] - l_e[i]
                if new_diff < min_diff:
                    min_diff = new_diff
                    min_j = j
            else:
                raise("Should never get here!")

            #print("min_diff", min_diff)
            #print("min_j", min_j)
            output_ridx[i] = min_j
            output_dist[i] = min_diff
            min_diff = cn.INT_MAX
            i += 1
            j = min_j
            inc_j = 0

        j += inc_j

    return output_arr_ridx, output_arr_dist



@cython.boundscheck(False)
@cython.wraparound(False)
cpdef nearest_nonoverlapping(long [::1] l_s, long [::1] l_e, long [::1] r_s, long [::1] r_e):

    cdef long [::1] prev_ridx
    cdef long [::1] prev_dist

    cdef long [::1] next_ridx
    cdef long [::1] next_dist

    cdef int i = 0

    cdef int length = len(l_s)

    prev_ridx_arr, prev_dist_arr = nearest_previous_nonoverlapping(l_s, r_s, r_e)
    next_ridx_arr, next_dist_arr = nearest_next_nonoverlapping(l_e, r_s)

    prev_ridx, prev_dist = prev_ridx_arr, prev_dist_arr
    next_ridx, next_dist = next_ridx_arr, next_dist_arr

    prev_dist_arr[prev_dist_arr == -1] = cn.INT_MAX
    next_dist_arr[next_dist_arr == -1] = cn.INT_MAX

    output_arr_ridx = np.ones(length, dtype=np.long) * -1
    output_arr_dist = np.ones(length, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist
    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    for i in range(length):
        if prev_dist[i] < next_dist[i]:
            output_ridx[i] = prev_ridx[i]
            output_dist[i] = prev_dist[i]
            i += 1
        else:
            output_ridx[i] = next_ridx[i]
            output_dist[i] = next_dist[i]
            i += 1

    output_arr_dist[output_arr_dist == cn.INT_MAX] = -1

    return output_arr_ridx, output_arr_dist




@cython.boundscheck(True)
@cython.wraparound(False)
cpdef nearest_previous_nonoverlapping(long [::1] l_s, long [::1] r_s, long [::1] r_e):

    print("nearest previous nonoverlapping " * 10)

    cdef int j = 0
    cdef int i = 0
    cdef int k = 0
    cdef int min_dist = cn.INT_MAX
    cdef int new_diff = cn.INT_MAX
    cdef int next_start = 0
    cdef int found = 0
    cdef int passed = 0
    cdef int min_j = 0
    cdef int rewind = 0
    cdef int _continue = 0
    cdef int length_l = len(l_s)
    cdef int length_r = len(r_e)
    cdef int length_l_minus_one = len(l_s) - 1
    cdef int length_r_minus_one = len(r_s) - 1

    output_arr_ridx = np.ones(length_l, dtype=np.long) * -1
    output_arr_dist = np.ones(length_l, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    while i < length_l and j < length_r:

        print("----")
        print("i", i, "j", j)
        print("output_ridx", output_arr_ridx)
        print("output_dist", output_arr_dist)
        if l_s[i] > r_e[j]:
            print("l_s[i] > r_e[j]", l_s[i], r_e[j])
            new_diff = l_s[i] - r_e[j]
            print("new_diff", l_s[i] - r_e[j])
            if new_diff < min_dist:
                # output_ridx[i] = j
                # output_dist[i] = new_diff
                min_dist = new_diff
                min_j = j
                found = 1
            print("min_dist", min_dist)
        elif r_s[j] >= l_s[i]:
            print("elif r_s[j] >= l_s[i]", r_s[j], l_s[i])
            print("min_dist", min_dist)
            passed = 1

        if found and passed:
            print("found and passed")
            output_ridx[i] = min_j
            output_dist[i] = min_dist
            min_dist = cn.INT_MAX
            found = 0
            passed = 0
            rewind = 1
        elif not found and passed:
            print("not found and passed")
            rewind = 1
            passed = 0
        elif found and i == length_l_minus_one and j == length_r_minus_one:
            print("found and i == length_l_minus_one and j == length_r_minus_one")
            output_ridx[i] = min_j
            output_dist[i] = min_dist
            min_dist = cn.INT_MAX
            j += 1
        elif found and j == length_r_minus_one and not i == length_l_minus_one:
            print("found and j == length_r_minus_one and not i == length_l_minus_one")
            output_ridx[i] = min_j
            output_dist[i] = min_dist
            min_dist = cn.INT_MAX
            rewind = 1
        elif j == length_r_minus_one and not i == length_l_minus_one:
            print("j == length_r_minus_one and not i == length_l_minus_one")
            rewind = 1
        elif not passed:
            print("not passed")
            j += 1

        if rewind:
            if i == length_l_minus_one:
                next_start = l_s[i]
                i+= 1
            else:
                i += 1
                next_start = l_s[i]

            k = j
            print("k", k)
            print("next_start", next_start)
            _continue = 1
            while k >= 0 and _continue:
                print("r_e[k] < next_start", r_e[k], next_start)
                if r_e[k] < next_start:
                    _continue = 0
                j = k
                k -= 1
            rewind = 0




    print("after " * 10)
    print("output_ridx", output_arr_ridx)
    print("output_dist", output_arr_dist)

    return output_arr_ridx, output_arr_dist





    # dist out of the leftones that have no entries in right previous
    # print("l_s[i] <= r_e[0]", l_s[i], r_e[0])
    # while i < length_l and l_s[i] <= r_e[0]:
    #     print("in here!")
    #     i += 1

    # print("i", i)

    # while i < length_l and j < length_r:

    #     if l_s[i] >= r_e[j]:
    #         print("l_s[i] >= r_e[j]", l_s[i], r_e[j])
    #         output_dist[i] = l_s[i] - r_e[j]
    #         j += 1
    #     else:
    #         print("else: l_s[i], r_e[j]", l_s[i], r_e[j])
    #         j -= 1
    #         output_ridx[i] = j
    #         i += 1

    # print("ridx", output_arr_ridx)
    # print(output_arr_dist)
    # cdef int length_r_minus_one = length_r - 1
    # while i < length_l:

    #     if r_e[length_r_minus_one] < l_s[i]:
    #         output_dist[i] = l_s[i] - r_e[length_r_minus_one]
    #         output_ridx[i] = length_r_minus_one
    #     i += 1



@cython.boundscheck(True)
@cython.wraparound(False)
cpdef nearest_next_nonoverlapping(long [::1] l_e, long [::1] r_s):

    cdef int diff
    cdef int j = 0
    cdef int found = 0
    cdef int next_end = 0
    # cdef int min_dist = 0
    cdef int i = 0
    cdef int k = 0
    cdef int rewind = 0
    cdef int length_l = len(l_e)
    cdef int length_l_m1 = len(l_e) - 1
    cdef int length_r = len(r_s)
    cdef int length_r_m1 = len(r_s) - 1

    output_arr_ridx = np.ones(length_l, dtype=np.long) * -1
    output_arr_dist = np.ones(length_l, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    print("nearest next" *  5)
    while i < length_l and j < length_r:

        print("---" * 3)
        print("i", i, "j", j)
        if l_e[i] < r_s[j]:
            output_dist[i] = r_s[j] - l_e[i]
            output_ridx[i] = j
            found = 1
        else:
            print("l_e[i] >= r_s[j]", l_e[i], r_s[j])

        if found:
            print("found and i < length_l_m1")
            if i < length_l_m1:
                rewind = 1
            i+=1
            found = 0
        elif i < length_l and j == length_r_m1:
            print("elif i < length_l and j == length_r")
            rewind = 1
            i += 1
        else:
            print("else")
            j += 1

        if rewind and not i == length_l:
            next_end = l_e[i]
            k = j
            print("k", k)
            print("next_end", next_end)
            while k >= 0 and r_s[k] > next_end:
                print("r_s[k] > next_end", r_s[k], next_end)
                j = k
                k -= 1
            rewind = 0

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    return output_arr_ridx, output_arr_dist


@cython.boundscheck(False)
@cython.wraparound(False)
cpdef nearest_next(long [::1] l_s, long [::1] l_e, long [::1] r_s, long [::1] r_e):

    cdef int diff
    cdef int j = 0
    cdef int i = 0
    cdef int ZERO = 0
    cdef int length_l = len(l_e)
    cdef int length_r = len(r_s)

    output_arr_ridx = np.ones(length_l, dtype=np.long) * -1
    output_arr_dist = np.ones(length_l, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist


    while i < length_l and j < length_r:

        if l_e[i] < r_s[j]:
            output_dist[i] = r_s[j] - l_e[i]
            output_ridx[i] = j
            i += 1
        elif r_e[j] < l_s[i]: # non-overlapping and non-next
            j += 1
        else: # overlap
            output_dist[i] = 0
            output_ridx[i] = j
            i += 1

    return output_arr_ridx, output_arr_dist


@cython.boundscheck(False)
@cython.wraparound(False)
cpdef nearest_previous(long [::1] l_s, long [::1] l_e, long [::1] r_s, long [::1] r_e):

    cdef int _continue = 1
    cdef int new_diff
    cdef int old_diff = cn.INT_MAX
    cdef int j = 0
    cdef int i = 0
    cdef int ZERO = 0
    cdef int length_l = len(l_s)
    cdef int length_r_minus_one = len(r_s) - 1

    output_arr_ridx = np.ones(length_l, dtype=np.long) * -1
    output_arr_dist = np.ones(length_l, dtype=np.long) * -1
    cdef long [::1] output_ridx
    cdef long [::1] output_dist

    output_ridx = output_arr_ridx
    output_dist = output_arr_dist

    # since the main loop checks j + 1, need this step for checking index zero
    while _continue and i < length_l:
        # print("while j == 0")
        if l_e[i] < r_s[0]:
            # print("  l_e[i] < r_s[0]")
            i += 1
        elif l_s[i] > r_e[0]:
            # print("  l_s[i] > r_e[0]")
            old_diff = l_s[i] - r_e[0]
            _continue = 0
        else: # overlapping
            # print("  overlapping")
            output_ridx[i] = 0
            output_dist[i] = 0
            i += 1

    while i < length_l and j < length_r_minus_one:

        if l_e[i] < r_s[j + 1]:
            # print("l_e[i] < r_s[j + 1]")
            output_ridx[i] = j
            output_dist[i] = old_diff
            old_diff = cn.INT_MAX
            j -= 1
            i += 1

        elif l_s[i] > r_e[j + 1]:
            # print("l_s[i] > r_e[j + 1]")
            new_diff = l_s[i] - r_e[j + 1]
            if new_diff > old_diff:
                # print("  Pushing", i, j, old_diff)
                output_ridx[i] = j
                output_dist[i] = old_diff
                old_diff = cn.INT_MAX
                j -= 1
                i += 1
            else:
                j += 1
                old_diff = new_diff
        else: # overlapping
            # print("else")
            # print("  Pushing", i, j, 0)
            j += 1
            output_ridx[i] = j
            output_dist[i] = 0
            old_diff = cn.INT_MAX
            j -= 1
            i += 1


    # might be a tie against last and second last since we could not check j == len(r)
    # in prev loop
    cdef int second_last = len(r_s) - 2
    cdef int last = len(r_s) - 1
    cdef int sl_dist, l_dist
    if len(r_s) >= 2:
        while i < length_l:
            # print("we are here")
            if l_e[i] < r_s[second_last]:
                # print("l_e[i] < r_s[second_last]")
                # print(l_e[i], r_s[second_last])
                sl_dist = r_s[second_last] - l_e[i]
            elif l_s[i] > r_e[second_last]:
                # print("l_s[i] > r_e[second_last]")
                # print(l_s[i], r_e[second_last])
                sl_dist = l_s[i] - r_e[second_last]
            else:
                sl_dist = 0

            if l_e[i] < r_s[last]:
                # print("l_e[i] < r_s[last]")
                # print(l_e[i], r_s[last])
                l_dist = r_s[last] - l_e[i]
            elif l_s[i] > r_e[last]:
                # print("l_s[i] > r_e[last]")
                # print(l_s[i], r_e[last])
                l_dist = l_s[i] - r_e[last]
            else:
                # print("else ldist=0")
                l_dist = 0

            # print("sl_dist", sl_dist, "l_dist", l_dist)
            if sl_dist < l_dist:
                # print(" Pushing", second_last, sl_dist)
                output_ridx[i] = second_last
                output_dist[i] = sl_dist
            else:
                # print(" Pushing", last, l_dist)
                output_ridx[i] = last
                output_dist[i] = l_dist

            i += 1

    else:
        while i < length_l:
            if l_s[i] > r_e[0]:
                output_ridx[i] = 0
                output_dist[i] = l_s[i] - r_e[0]
            elif r_e[0] < l_s[i]:
                pass
            else:
                output_ridx[i] = 0
                output_dist[i] = 0

            i += 1

    return output_arr_ridx, output_arr_dist
