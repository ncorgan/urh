from urh.dev.native.lib.cusrp cimport *
import numpy as np

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdlib cimport malloc, free
# noinspection PyUnresolvedReferences
from cython.view cimport array as cvarray  # needed for converting of malloc array to python array

import cython

cpdef foo():
    return SOAPY_SDR_TX
