# TODO: consistency in whether to throw here or in Python layer

from urh.dev.native.lib.csoapysdr cimport *
import numpy as np

from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy
# noinspection PyUnresolvedReferences
from cython.view cimport array as cvarray  # needed for converting of malloc array to python array

import cython

cdef SoapySDRDevice* _c_device = NULL
cdef SoapySDRStream* _c_stream = NULL

cpdef int DIRECTION = SOAPY_SDR_TX
cpdef size_t CHANNEL = 0
cpdef size_t MTU = 0

#
# Utility
#

cpdef __throw_for_device_status(str context):
    last_status = SoapySDRDevice_lastStatus()
    if last_status != 0:
        raise RuntimeError(context + ": " + <bytes>SoapySDR_errToStr(last_status))

cpdef __throw_for_device_error(str context):
    last_error = SoapySDRDevice_lastError()
    if last_error:
        raise RuntimeError(context + ": " + <bytes>last_error)

cpdef check_device_call(str context):
    __throw_for_device_status(context)
    __throw_for_device_error(context)

cdef str __alloc_str_to_python(char *c_str):
    try:
        return <str><bytes>c_str.decode("utf-8")
    finally:
        SoapySDR_free(c_str)

cdef list __soapysdr_stringlist_to_python(char **c_strs, size_t length):
    strs = []
    for i in range(length):
        strs.append(c_strs[i].decode("utf-8"))

    return strs

cdef list __soapysdr_kwargslist_to_python(SoapySDRKwargs *kwargs, size_t length):
    try:
        strs = []
        for i in range(length):
            strs.append(__alloc_str_to_python(SoapySDRKwargs_toString(&kwargs[i])))

        return strs
    finally:
        SoapySDRKwargsList_clear(kwargs, length)

#
# Construction/Identification
#

cpdef bool make(str device_args):
    if not device_args:
        device_args = ""

    _c_device = SoapySDRDevice_makeStrArgs(device_args)
    if not _c_device:
        raise ValueError("Invalid args: "+device_args)

    return True

cpdef unmake():
    global _c_device

    if _c_device:
        SoapySDRDevice_unmake(_c_device)
        _c_device = NULL

cpdef str get_device_repr():
    hw_info = SoapySDRDevice_getHardwareInfo(_c_device)

    try:
        return __alloc_str_to_python(SoapySDRKwargs_toString(&hw_info))
    finally:
        SoapySDRKwargs_clear(&hw_info)

#
# Configuration
#

cpdef set_tx(bool is_tx):
    global DIRECTION
    DIRECTION = SOAPY_SDR_TX if is_tx else SOAPY_SDR_RX

cpdef set_channel(size_t channel):
    global CHANNEL

    # Check if we can.
    if _c_device:
        nchans = SoapySDRDevice_getNumChannels(_c_device, DIRECTION)
        if channel >= nchans:
            raise ValueError("Invalid channel {} (valid 0-{0})".format(channel, (nchans-1)))

    CHANNEL = channel

cpdef set_frontend_mapping(str mapping):
    if not mapping:
        mapping = ""

    SoapySDRDevice_setFrontendMapping(_c_device, DIRECTION, mapping)

cpdef set_sample_rate(double sample_rate):
    SoapySDRDevice_setSampleRate(_c_device, DIRECTION, CHANNEL, sample_rate)
    check_device_call("set_sample_rate")

cpdef set_bandwidth(double bandwidth):
    SoapySDRDevice_setBandwidth(_c_device, DIRECTION, CHANNEL, bandwidth)
    check_device_call("set_bandwidth")

cpdef str get_antenna():
    ret = __alloc_str_to_python(SoapySDRDevice_getAntenna(_c_device, DIRECTION, CHANNEL))
    check_device_call("get_antenna")
    return ret

cpdef set_antenna(int index):
    cdef antennas = get_antennas()
    if index < 0 or index >= len(antennas):
        raise IndexError("Invalid antenna index {} (valid 0-{})".format(index, len(antennas)-1))

    cdef antenna_bytes = antennas[index].encode("utf-8")
    SoapySDRDevice_setAntenna(_c_device, DIRECTION, CHANNEL, antenna_bytes)
    check_device_call("set_antenna")

cpdef list get_antennas():
    cdef size_t num_antennas = 0
    cdef char **antennas_c = SoapySDRDevice_listAntennas(_c_device, DIRECTION, CHANNEL, &num_antennas)

    try:
        return __soapysdr_stringlist_to_python(antennas_c, num_antennas)
    finally:
        SoapySDRStrings_clear(&antennas_c, num_antennas)

cpdef list find_devices():
    cdef size_t length = 0
    cdef SoapySDRKwargs *devs = SoapySDRDevice_enumerateStrArgs("", &length)
    return __soapysdr_kwargslist_to_python(devs, length)

#
# Streaming
#

cpdef setup_stream():
    global MTU

    cdef size_t chan = CHANNEL
    _c_stream = SoapySDRDevice_setupStream(
        _c_device,
        DIRECTION,
        "CF32",
        &chan,
        1,
        NULL)
    check_device_call("setup_stream")

    # We shouldn't have gotten to this point if we failed to set up
    # the stream.
    if not _c_stream:
        raise RuntimeError("Failed to initialize stream")

    MTU = SoapySDRDevice_getStreamMTU(_c_device, _c_stream)
    check_device_call("get_stream_mtu")

cpdef int activate_stream(size_t num_samples = 0):
    return SoapySDRDevice_activateStream(
        _c_device,
        _c_stream,
        0,
        0,
        num_samples)

cpdef int deactivate_stream():
    return SoapySDRDevice_deactivateStream(
        _c_device,
        _c_stream,
        0,
        0)

cpdef int close_stream():
    global _c_stream

    ret = SoapySDRDevice_closeStream(_c_device, _c_stream)
    _c_stream = NULL

    return ret
