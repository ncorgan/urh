from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t
from libcpp cimport bool

cdef extern from "SoapySDR/Constants.h":
    const int SOAPY_SDR_TX "SOAPY_SDR_TX"
    const int SOAPY_SDR_RX "SOAPY_SDR_RX"

    const int SOAPY_SDR_END_BURST "SOAPY_SDR_END_BURST"
    const int SOAPY_SDR_HAS_TIME "SOAPY_SDR_HAS_TIME"
    const int SOAPY_SDR_END_ABRUPT "SOAPY_SDR_END_ABRUPT"
    const int SOAPY_SDR_ONE_PACKET "SOAPY_SDR_ONE_PACKET"
    const int SOAPY_SDR_MORE_FRAGMENTS "SOAPY_SDR_MORE_FRAGMENTS"
    const int SOAPY_SDR_WAIT_TRIGGER "SOAPY_SDR_WAIT_TRIGGER"

# TODO: remove unused functions
cdef extern from "SoapySDR/Device.h":
    struct SoapySDRDevice
    struct SoapySDRStream

    int SoapySDRDevice_lastStatus()
    const char *SoapySDRDevice_lastError()
    SoapySDRKwargs *SoapySDRDevice_enumerate(const SoapySDRKwargs *args, size_t *length)
    SoapySDRKwargs *SoapySDRDevice_enumerateStrArgs(const char *args, size_t *length)
    SoapySDRDevice *SoapySDRDevice_make(const SoapySDRKwargs *args)
    SoapySDRDevice *SoapySDRDevice_makeStrArgs(const char *args)
    int SoapySDRDevice_unmake(SoapySDRDevice *device)
    char *SoapySDRDevice_getDriverKey(const SoapySDRDevice *device)
    char *SoapySDRDevice_getHardwareKey(const SoapySDRDevice *device)
    SoapySDRKwargs SoapySDRDevice_getHardwareInfo(const SoapySDRDevice *device)
    int SoapySDRDevice_setFrontendMapping(SoapySDRDevice *device, const int direction, const char *mapping)
    char *SoapySDRDevice_getFrontendMapping(const SoapySDRDevice *device, const int direction)
    size_t SoapySDRDevice_getNumChannels(const SoapySDRDevice *device, const int direction)
    SoapySDRKwargs SoapySDRDevice_getChannelInfo(const SoapySDRDevice *device, const int direction, const size_t channel)
    bool SoapySDRDevice_getFullDuplex(const SoapySDRDevice *device, const int direction, const size_t channel)
    char **SoapySDRDevice_getStreamFormats(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    char *SoapySDRDevice_getNativeStreamFormat(const SoapySDRDevice *device, const int direction, const size_t channel, double *fullScale)
    SoapySDRArgInfo *SoapySDRDevice_getStreamArgsInfo(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRStream *SoapySDRDevice_setupStream(SoapySDRDevice *device,
        const int direction,
        const char *format,
        const size_t *channels,
        const size_t numChans,
        const SoapySDRKwargs *args)
    int SoapySDRDevice_closeStream(SoapySDRDevice *device, SoapySDRStream *stream)
    size_t SoapySDRDevice_getStreamMTU(const SoapySDRDevice *device, SoapySDRStream *stream)
    int SoapySDRDevice_activateStream(SoapySDRDevice *device,
        SoapySDRStream *stream,
        const int flags,
        const long long timeNs,
        const size_t numElems)
    int SoapySDRDevice_deactivateStream(SoapySDRDevice *device,
        SoapySDRStream *stream,
        const int flags,
        const long long timeNs)
    int SoapySDRDevice_readStream(SoapySDRDevice *device,
        SoapySDRStream *stream,
        void * const *buffs,
        const size_t numElems,
        int *flags,
        long long *timeNs,
        const long timeoutUs)
    int SoapySDRDevice_writeStream(SoapySDRDevice *device,
        SoapySDRStream *stream,
        const void * const *buffs,
        const size_t numElems,
        int *flags,
        const long long timeNs,
        const long timeoutUs)
    int SoapySDRDevice_readStreamStatus(SoapySDRDevice *device,
        SoapySDRStream *stream,
        size_t *chanMask,
        int *flags,
        long long *timeNs,
        const long timeoutUs)
    char **SoapySDRDevice_listAntennas(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    int SoapySDRDevice_setAntenna(SoapySDRDevice *device, const int direction, const size_t channel, const char *name)
    char *SoapySDRDevice_getAntenna(const SoapySDRDevice *device, const int direction, const size_t channel)
    bool SoapySDRDevice_hasDCOffsetMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setDCOffsetMode(SoapySDRDevice *device, const int direction, const size_t channel, const bool automatic)
    bool SoapySDRDevice_getDCOffsetMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    bool SoapySDRDevice_hasDCOffset(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setDCOffset(SoapySDRDevice *device, const int direction, const size_t channel, const double offsetI, const double offsetQ)
    int SoapySDRDevice_getDCOffset(const SoapySDRDevice *device, const int direction, const size_t channel, double *offsetI, double *offsetQ)
    bool SoapySDRDevice_hasIQBalance(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setIQBalance(SoapySDRDevice *device, const int direction, const size_t channel, const double balanceI, const double balanceQ)
    int SoapySDRDevice_getIQBalance(const SoapySDRDevice *device, const int direction, const size_t channel, double *balanceI, double *balanceQ)
    bool SoapySDRDevice_hasIQBalanceMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setIQBalanceMode(SoapySDRDevice *device, const int direction, const size_t channel, const bool automatic)
    bool SoapySDRDevice_getIQBalanceMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    bool SoapySDRDevice_hasFrequencyCorrection(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setFrequencyCorrection(SoapySDRDevice *device, const int direction, const size_t channel, const double value)
    double SoapySDRDevice_getFrequencyCorrection(const SoapySDRDevice *device, const int direction, const size_t channel)
    char **SoapySDRDevice_listGains(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    bool SoapySDRDevice_hasGainMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setGainMode(SoapySDRDevice *device, const int direction, const size_t channel, const bool automatic)
    bool SoapySDRDevice_getGainMode(const SoapySDRDevice *device, const int direction, const size_t channel)
    int SoapySDRDevice_setGain(SoapySDRDevice *device, const int direction, const size_t channel, const double value)
    int SoapySDRDevice_setGainElement(SoapySDRDevice *device, const int direction, const size_t channel, const char *name, const double value)
    double SoapySDRDevice_getGain(const SoapySDRDevice *device, const int direction, const size_t channel)
    double SoapySDRDevice_getGainElement(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name)
    SoapySDRRange SoapySDRDevice_getGainRange(const SoapySDRDevice *device, const int direction, const size_t channel)
    SoapySDRRange SoapySDRDevice_getGainElementRange(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name)
    int SoapySDRDevice_setFrequency(SoapySDRDevice *device, const int direction, const size_t channel, const double frequency, const SoapySDRKwargs *args)
    int SoapySDRDevice_setFrequencyComponent(SoapySDRDevice *device, const int direction, const size_t channel, const char *name, const double frequency, const SoapySDRKwargs *args)
    double SoapySDRDevice_getFrequency(const SoapySDRDevice *device, const int direction, const size_t channel)
    double SoapySDRDevice_getFrequencyComponent(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name)
    char **SoapySDRDevice_listFrequencies(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRRange *SoapySDRDevice_getFrequencyRange(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRRange *SoapySDRDevice_getFrequencyRangeComponent(const SoapySDRDevice *device, const int direction, const size_t channel, const char *name, size_t *length)
    SoapySDRArgInfo *SoapySDRDevice_getFrequencyArgsInfo(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    int SoapySDRDevice_setSampleRate(SoapySDRDevice *device, const int direction, const size_t channel, const double rate)
    double SoapySDRDevice_getSampleRate(const SoapySDRDevice *device, const int direction, const size_t channel)
    double *SoapySDRDevice_listSampleRates(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRRange *SoapySDRDevice_getSampleRateRange(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    int SoapySDRDevice_setBandwidth(SoapySDRDevice *device, const int direction, const size_t channel, const double bw)
    double SoapySDRDevice_getBandwidth(const SoapySDRDevice *device, const int direction, const size_t channel)
    double *SoapySDRDevice_listBandwidths(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRRange *SoapySDRDevice_getBandwidthRange(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    int SoapySDRDevice_setMasterClockRate(SoapySDRDevice *device, const double rate)
    double SoapySDRDevice_getMasterClockRate(const SoapySDRDevice *device)
    SoapySDRRange *SoapySDRDevice_getMasterClockRates(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_setReferenceClockRate(SoapySDRDevice *device, const double rate)
    double SoapySDRDevice_getReferenceClockRate(const SoapySDRDevice *device)
    SoapySDRRange *SoapySDRDevice_getReferenceClockRates(const SoapySDRDevice *device, size_t *length)
    char **SoapySDRDevice_listClockSources(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_setClockSource(SoapySDRDevice *device, const char *source)
    char *SoapySDRDevice_getClockSource(const SoapySDRDevice *device)
    char **SoapySDRDevice_listTimeSources(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_setTimeSource(SoapySDRDevice *device, const char *source)
    char *SoapySDRDevice_getTimeSource(const SoapySDRDevice *device)
    bool SoapySDRDevice_hasHardwareTime(const SoapySDRDevice *device, const char *what)
    long long SoapySDRDevice_getHardwareTime(const SoapySDRDevice *device, const char *what)
    int SoapySDRDevice_setHardwareTime(SoapySDRDevice *device, const long long timeNs, const char *what)
    int SoapySDRDevice_setCommandTime(SoapySDRDevice *device, const long long timeNs, const char *what)
    char **SoapySDRDevice_listSensors(const SoapySDRDevice *device, size_t *length)
    SoapySDRArgInfo SoapySDRDevice_getSensorInfo(const SoapySDRDevice *device, const char *key)
    char *SoapySDRDevice_readSensor(const SoapySDRDevice *device, const char *key)
    char **SoapySDRDevice_listChannelSensors(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    SoapySDRArgInfo SoapySDRDevice_getChannelSensorInfo(const SoapySDRDevice *device, const int direction, const size_t channel, const char *key)
    char *SoapySDRDevice_readChannelSensor(const SoapySDRDevice *device, const int direction, const size_t channel, const char *key)
    char **SoapySDRDevice_listRegisterInterfaces(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_writeRegister(SoapySDRDevice *device, const char *name, const unsigned addr, const unsigned value)
    unsigned SoapySDRDevice_readRegister(const SoapySDRDevice *device, const char *name, const unsigned addr)
    int SoapySDRDevice_writeRegisters(SoapySDRDevice *device, const char *name, const unsigned addr, const unsigned *value, const size_t length)
    unsigned *SoapySDRDevice_readRegisters(const SoapySDRDevice *device, const char *name, const unsigned addr, size_t *length)
    SoapySDRArgInfo *SoapySDRDevice_getSettingInfo(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_writeSetting(SoapySDRDevice *device, const char *key, const char *value)
    char *SoapySDRDevice_readSetting(const SoapySDRDevice *device, const char *key)
    SoapySDRArgInfo *SoapySDRDevice_getChannelSettingInfo(const SoapySDRDevice *device, const int direction, const size_t channel, size_t *length)
    int SoapySDRDevice_writeChannelSetting(SoapySDRDevice *device, const int direction, const size_t channel, const char *key, const char *value)
    char *SoapySDRDevice_readChannelSetting(const SoapySDRDevice *device, const int direction, const size_t channel, const char *key)
    char **SoapySDRDevice_listGPIOBanks(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_writeGPIO(SoapySDRDevice *device, const char *bank, const unsigned value)
    int SoapySDRDevice_writeGPIOMasked(SoapySDRDevice *device, const char *bank, const unsigned value, const unsigned mask)
    unsigned SoapySDRDevice_readGPIO(const SoapySDRDevice *device, const char *bank)
    int SoapySDRDevice_writeGPIODir(SoapySDRDevice *device, const char *bank, const unsigned dir)
    int SoapySDRDevice_writeGPIODirMasked(SoapySDRDevice *device, const char *bank, const unsigned dir, const unsigned mask)
    unsigned SoapySDRDevice_readGPIODir(const SoapySDRDevice *device, const char *bank)
    int SoapySDRDevice_writeI2C(SoapySDRDevice *device, const int addr, const char *data, const size_t numBytes)
    char *SoapySDRDevice_readI2C(SoapySDRDevice *device, const int addr, size_t *numBytes)
    unsigned SoapySDRDevice_transactSPI(SoapySDRDevice *device, const int addr, const unsigned data, const size_t numBits)
    char **SoapySDRDevice_listUARTs(const SoapySDRDevice *device, size_t *length)
    int SoapySDRDevice_writeUART(SoapySDRDevice *device, const char *which, const char *data)
    char *SoapySDRDevice_readUART(const SoapySDRDevice *device, const char *which, const long timeoutUs)

cdef extern from "SoapySDR/Errors.h":
    const char *SoapySDR_errToStr(const int errorCode)

cdef extern from "SoapySDR/Formats.h":
    size_t SoapySDR_formatToSize(const char *format)

cdef extern from "SoapySDR/Logger.h":
    ctypedef enum SoapySDRLogLevel:
        SOAPY_SDR_FATAL = 1
        SOAPY_SDR_CRITICAL
        SOAPY_SDR_ERROR
        SOAPY_SDR_WARNING
        SOAPY_SDR_NOTICE
        SOAPY_SDR_INFO
        SOAPY_SDR_DEBUG
        SOAPY_SDR_TRACE
        SOAPY_SDR_SSI

    ctypedef void (*SoapySDRLogHandler)(const SoapySDRLogLevel logLevel, const char *message);

    void SoapySDR_log(const SoapySDRLogLevel logLevel, const char *message)
    void SoapySDR_registerLogHandler(const SoapySDRLogHandler handler)
    void SoapySDR_setLogLevel(const SoapySDRLogLevel logLevel)

cdef extern from "SoapySDR/Types.h":
    ctypedef struct SoapySDRRange:
        double minimum
        double maximum
        double step

    ctypedef struct SoapySDRKwargs:
        size_t size
        char **keys
        char **vals

    SoapySDRKwargs SoapySDRKwargs_fromString(const char *markup)
    char *SoapySDRKwargs_toString(const SoapySDRKwargs *args)

    ctypedef enum SoapySDRArgInfoType:
        SOAPY_SDR_ARG_INFO_BOOL
        SOAPY_SDR_ARG_INFO_INT
        SOAPY_SDR_ARG_INFO_FLOAT
        SOAPY_SDR_ARG_INFO_STRING

    ctypedef struct SoapySDRArgInfo:
        char *value
        char *name
        char *description
        char *units
        SoapySDRArgInfoType type
        SoapySDRRange range
        size_t numOptions
        char **options
        char **optionNames

    void SoapySDR_free(void *ptr)
    void SoapySDRStrings_clear(char ***elems, const size_t length)
    int SoapySDRKwargs_set(SoapySDRKwargs *args, const char *key, const char *val)
    const char *SoapySDRKwargs_get(const SoapySDRKwargs *args, const char *key)
    void SoapySDRKwargs_clear(SoapySDRKwargs *args)
    void SoapySDRKwargsList_clear(SoapySDRKwargs *args, const size_t length)
    void SoapySDRArgInfo_clear(SoapySDRArgInfo *info)
    void SoapySDRArgInfoList_clear(SoapySDRArgInfo *info, const size_t length)
