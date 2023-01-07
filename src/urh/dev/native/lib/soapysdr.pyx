# TODO: consistency in whether to throw here or in Python layer
# TODO: make returns make sense

from urh.dev.native.lib.csoapysdr cimport *
from urh.util.Logger import logger

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
    if _c_stream:
        raise RuntimeError("Cannot set TX/RX once the stream is active")

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

cpdef int recv_stream(connection, size_t num_samples):
    cdef float* result = <float *>(num_samples * 2 * sizeof(float))
    if not result:
        raise MemoryError()

    cdef int read_ret = 0
    cdef size_t current_index = 0
    cdef int flags = 0
    cdef long long time_ns = 0
    cdef long timeout_us = 100000

    # This is based on the USRP implementation. Do either need the intermediate buffer?
    cdef float* buff = <float *>malloc(MTU * 2 * sizeof(float))
    cdef void** buffs = <void **>&buff

    try:
        while current_index < (num_samples*2):
            flags = 0
            time_ns = 0

            read_length = min(num_samples, MTU)
            read_ret = SoapySDRDevice_readStream(
                _c_device,
                _c_stream,
                <void**>buffs,
                read_length,
                &flags,
                &time_ns,
                timeout_us)
            check_device_call("recv_stream")

            if read_ret >= 0:
                memcpy(&result[current_index], &buff[0], 2 * read_ret * sizeof(float))
                current_index += (read_ret * 2)
            else:
                # Error code
                return read_ret

        connection.send_bytes(<float[:2*num_samples]>result)
        return 0
    finally:
        free(buff)
        free(result)

@cython.boundscheck(False)
@cython.initializedcheck(False)
@cython.wraparound(False)
cpdef int send_stream(float[::1] samples):
    if len(samples) == 1 and samples[0] == 0:
        # Fill with zeros. Use some more zeros to prevent underflows
        samples = np.zeros(8 * MTU, dtype=np.float32)

    cdef unsigned long i, index = 0
    cdef soapy_ret = 0
    cdef size_t sample_count = len(samples)

    cdef int flags = 0
    cdef long long time_ns = 0
    cdef long timeout_us = 100000

    cdef float* buff = <float *>malloc(MTU * 2 * sizeof(float))
    if not buff:
        raise MemoryError()

    cdef const void ** buffs = <const void **> &buff

    try:
        for i in range(0, sample_count):
            buff[index] = samples[i]
            index += 1
            if index >= (2 * MTU):
                index = 0
                if i == (sample_count - 1):
                    flags = SOAPY_SDR_END_BURST

                soapy_ret = SoapySDRDevice_writeStream(
                    _c_device,
                    _c_stream,
                    buffs,
                    MTU,
                    &flags,
                    time_ns,
                    timeout_us);
                check_device_call("send_stream")

                if soapy_ret < 0:
                    return soapy_ret

        return 0
    finally:
        free(buff)

cpdef int close_stream():
    global _c_stream

    ret = SoapySDRDevice_closeStream(_c_device, _c_stream)
    check_device_call("close_stream")
    _c_stream = NULL

    return ret

#
# Logging
#

cdef void __urh_soapy_log_handler(const SoapySDRLogLevel log_level, const char *message):
    py_message = "SoapySDR: "+message.encode("utf-8")

    if log_level >= SOAPY_SDR_DEBUG:
        logger.debug(py_message)
    elif log_level >= SOAPY_SDR_NOTICE:
        logger.info(py_message)
    elif log_level >= SOAPY_SDR_WARNING:
        logger.warning(py_message)
    elif log_level >= SOAPY_SDR_ERROR:
        logger.error(py_message)
    else:
        logger.critical(py_message)

cpdef __init_soapysdr_logging():
    # Forward everything to URH and let its logger deal with it.
    SoapySDR_setLogLevel(SOAPY_SDR_SSI)
    SoapySDR_registerLogHandler(&__urh_soapy_log_handler)
