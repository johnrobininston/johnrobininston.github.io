# Magic Squares

import numpy as np
import random

test = np.array([[4,3,8], [9,5,1], [2,7,6]])

# Function: Test if matrix is magic square
def magic_square_test(test):
    # return dimension
    if len(set(test.shape)) != 1:
        return False
    else:
        # test sums of rows, columns and main diagonals
        sum_list = [
            np.sum(test, axis=0),
            np.sum(test, axis=1),
            [np.sum(np.diag(test)),np.sum(np.diag(test.T))]
        ]
        flat_sum_list = [x for xs in sum_list for x in xs]
        if len(set(flat_sum_list)) == 1:
            return True
        else:
            return False

magic_square_test(test_square)

# Function: Brute force search for magic squares
def magic_square_search(n, less_than=True):
    if less_than == True:
        values = random.sample(np.linspace(1,n,n))
        square = np.array(values, )