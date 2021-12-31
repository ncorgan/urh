from collections import OrderedDict
from multiprocessing import Array
from multiprocessing.connection import Connection

import numpy as np

from urh.dev.native.Device import Device
from urh.dev.native.lib import soapysdr


class SoapySDR(Device):
    DEVICE_METHODS = Device.DEVICE_METHODS.copy()
    DEVICE_METHODS.update({"SET_SUBDEVICE": "set_subdevice", Device.Command.SET_ANTENNA_INDEX.name: "set_antenna"})

    SYNC_RX_CHUNK_SIZE = 16384
    SYNC_TX_CHUNK_SIZE = 16384 * 2
    CONTINUOUS_TX_CHUNK_SIZE = -1  # take everything from queue

    DEVICE_LIB = soapysdr
    ASYNCHRONOUS = False

    DATA_TYPE = np.float32

    @classmethod
    def get_device_list(cls):
        return soapysdr.find_devices("")

    @classmethod
    def adapt_num_read_samples_to_sample_rate(cls, sample_rate):
        cls.SYNC_RX_CHUNK_SIZE = 16384 * int(sample_rate / 1e6)

    @classmethod
    def setup_device(cls, ctrl_connection: Connection, device_identifier):
        ret = soapysdr.open(device_identifier)

        if device_identifier:
            ctrl_connection.send("OPEN ({}):{}".format(device_identifier, ret))
        else:
            ctrl_connection.send("OPEN:" + str(ret))

        success = ret == 0
        if success:
            device_repr = soapysdr.get_device_representation()
            ctrl_connection.send(device_repr)
        else:
            ctrl_connection.send(soapysdr.get_last_error())
        return success

    @classmethod
    def init_device(cls, ctrl_connection: Connection, is_tx: bool, parameters: OrderedDict):
        soapysdr.set_tx(is_tx)
        success = super().init_device(ctrl_connection, is_tx, parameters)
        if success:
            ctrl_connection.send("Current antenna is {} (possible antennas: {})".format(soapysdr.get_antenna(),
                                                                                        ", ".join(soapysdr.get_antennas())))
        return success

    @classmethod
    def shutdown_device(cls, ctrl_connection, is_tx: bool):
        soapysdr.deactivate_stream()
        soapysdr.close_stream()
        ret = soapysdr.close()
        ctrl_connection.send("CLOSE:" + str(ret))
        return True

    @classmethod
    def prepare_sync_receive(cls, ctrl_connection: Connection):
        ctrl_connection.send("Initializing stream...")
        soapysdr.setup_stream()
        return soapysdr.start_stream(cls.SYNC_RX_CHUNK_SIZE)

    @classmethod
    def receive_sync(cls, data_conn: Connection):
        soapysdr.recv_stream(data_conn, cls.SYNC_RX_CHUNK_SIZE)

    @classmethod
    def prepare_sync_send(cls, ctrl_connection: Connection):
        ctrl_connection.send("Initializing stream...")
        soapysdr.setup_stream()
        ret = soapysdr.start_stream(0)
        ctrl_connection.send("Initialize stream:{0}".format(ret))
        return ret

    @classmethod
    def send_sync(cls, data):
        soapysdr.send_stream(data)

    def __init__(self, center_freq, sample_rate, bandwidth, gain, if_gain=1, baseband_gain=1,
                 resume_on_full_receive_buffer=False):
        super().__init__(center_freq=center_freq, sample_rate=sample_rate, bandwidth=bandwidth,
                         gain=gain, if_gain=if_gain, baseband_gain=baseband_gain,
                         resume_on_full_receive_buffer=resume_on_full_receive_buffer)
        self.success = 0

        self.error_codes = {4711: "Antenna index not supported on this device"}

        self.subdevice = ""

    def set_device_gain(self, gain):
        super().set_device_gain(gain * 0.01)

    @property
    def has_multi_device_support(self):
        return True

    @property
    def device_parameters(self):
        return OrderedDict([
            ("SET_SUBDEVICE", self.subdevice),
            (self.Command.SET_ANTENNA_INDEX.name, self.antenna_index),
            (self.Command.SET_FREQUENCY.name, self.frequency),
            (self.Command.SET_SAMPLE_RATE.name, self.sample_rate),
            (self.Command.SET_BANDWIDTH.name, self.bandwidth),
            (self.Command.SET_RF_GAIN.name, self.gain * 0.01),
            ("identifier", self.device_serial),
        ])

    @staticmethod
    def bytes_to_iq(buffer):
        return np.frombuffer(buffer, dtype=np.float32).reshape((-1, 2), order="C")

    @staticmethod
    def iq_to_bytes(samples: np.ndarray):
        arr = Array("f", 2 * len(samples), lock=False)
        numpy_view = np.frombuffer(arr, dtype=np.float32)
        numpy_view[:] = samples.flatten(order="C")
        return arr
