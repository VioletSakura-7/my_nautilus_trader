# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------

"""
This module provides a data producer for backtesting.
"""

from cpython.datetime cimport datetime

from nautilus_trader.cache.cache cimport Cache
from nautilus_trader.common.clock cimport Clock
from nautilus_trader.common.logging cimport Logger
from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.uuid cimport UUID
from nautilus_trader.data.client cimport DataClient
from nautilus_trader.data.client cimport MarketDataClient
from nautilus_trader.model.c_enums.book_level cimport BookLevel
from nautilus_trader.model.data.bar cimport BarType
from nautilus_trader.model.data.base cimport DataType
from nautilus_trader.model.identifiers cimport ClientId
from nautilus_trader.model.identifiers cimport InstrumentId
from nautilus_trader.model.identifiers cimport Venue
from nautilus_trader.model.instruments.base cimport Instrument
from nautilus_trader.msgbus.message_bus cimport MessageBus


cdef class BacktestDataClient(DataClient):
    """
    Provides an implementation of `DataClient` for backtesting.
    """

    def __init__(
        self,
        ClientId client_id not None,
        MessageBus msgbus not None,
        Cache cache not None,
        Clock clock not None,
        Logger logger not None,
        dict config=None,
    ):
        """
        Initialize a new instance of the ``BacktestDataClient`` class.

        Parameters
        ----------
        client_id : ClientId
            The data client ID.
        msgbus : MessageBus
            The message bus for the client.
        cache : Cache
            The cache for the client.
        clock : Clock
            The clock for the client.
        logger : Logger
            The logger for the client.
        config : dict[str, object], optional
            The configuration options.

        """
        super().__init__(
            client_id=client_id,
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            logger=logger,
            config=config,
        )

        self.is_connected = False

    cpdef void _start(self) except *:
        self._log.info(f"Connecting...")
        self.is_connected = True
        self._log.info(f"Connected.")

    cpdef void _stop(self) except *:
        self._log.info(f"Disconnecting...")
        self.is_connected = False
        self._log.info(f"Disconnected.")

    cpdef void _reset(self) except *:
        pass
        # Nothing to reset

    cpdef void _dispose(self) except *:
        pass
        # Nothing to dispose

# -- SUBSCRIPTIONS ---------------------------------------------------------------------------------

    cpdef void subscribe(self, DataType data_type) except *:
        """
        Subscribe to the given data type.

        Parameters
        ----------
        data_type : DataType
            The data type to subscribe to.

        """
        Condition.not_none(data_type, "data_type")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(f"Cannot subscribe to {data_type} (not connected).")
            return

        self._feeds_generic_data[data_type] = None
        # Do nothing else for backtest

    cpdef void unsubscribe(self, DataType data_type) except *:
        """
        Unsubscribe from the given data type.

        Parameters
        ----------
        data_type : DataType
            The data_type to unsubscribe from.

        """
        Condition.not_none(data_type, "data_type")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(f"Cannot unsubscribe from {data_type} (not connected).")
            return

        self._feeds_generic_data.pop(data_type, None)
        # Do nothing else for backtest

# -- REQUESTS --------------------------------------------------------------------------------------

    cpdef void request(self, DataType data_type, UUID correlation_id) except *:
        """
        Request the given data type.

        Parameters
        ----------
        data_type : DataType
            The data type to request.
        correlation_id : UUID
            The correlation ID for the response.

        """
        Condition.not_none(data_type, "data_type")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(f"Cannot request {data_type} (not connected).")
            return

        # Do nothing else for backtest


cdef class BacktestMarketDataClient(MarketDataClient):
    """
    Provides an implementation of `MarketDataClient` for backtesting.
    """

    def __init__(
        self,
        ClientId client_id not None,
        MessageBus msgbus not None,
        Cache cache not None,
        Clock clock not None,
        Logger logger not None,
    ):
        """
        Initialize a new instance of the ``BacktestDataProducer`` class.

        Parameters
        ----------
        client_id : ClientId
            The data client ID.
        msgbus : MessageBus
            The message bus for the client.
        cache : Cache
            The cache for the client.
        clock : Clock
            The clock for the client.
        logger : Logger
            The logger for the client.

        """
        super().__init__(
            client_id=client_id,
            msgbus=msgbus,
            cache=cache,
            clock=clock,
            logger=logger,
        )

        self.is_connected = False

    cpdef void _start(self) except *:
        self._log.info(f"Connecting...")
        self.is_connected = True
        self._log.info(f"Connected.")

    cpdef void _stop(self) except *:
        self._log.info(f"Disconnecting...")
        self.is_connected = False
        self._log.info(f"Disconnected.")

    cpdef void _reset(self) except *:
        pass
        # Nothing to reset

    cpdef void _dispose(self) except *:
        pass
        # Nothing to dispose

# -- SUBSCRIPTIONS ---------------------------------------------------------------------------------

    cpdef void subscribe_instruments(self) except *:
        """
        Subscribe to `Instrument` data for the venue.

        """
        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to instruments (not connected).",
            )
            return

        cdef Instrument instrument
        for instrument in self._cache.instruments(Venue(self.id.value)):
            self._feeds_instrument.add(instrument.id)
        # Do nothing else for backtest

    cpdef void subscribe_instrument(self, InstrumentId instrument_id) except *:
        """
        Subscribe to `Instrument` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The instrument to subscribe to.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to instrument for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument.add(instrument_id)
        # Do nothing else for backtest

    cpdef void subscribe_order_book_snapshots(
        self,
        InstrumentId instrument_id,
        BookLevel level,
        int depth=0,
        dict kwargs=None,
    ) except *:
        """
        Subscribe to `OrderBook` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The order book instrument to subscribe to.
        level : BookLevel
            The order book level (L1, L2, L3).
        depth : int, optional
            The maximum depth for the order book. A depth of 0 is maximum depth.
        kwargs : dict, optional
            The keyword arguments for exchange specific parameters.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to order book for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_order_book_snapshot[instrument_id] = None
        # Do nothing else for backtest

    cpdef void subscribe_order_book_deltas(
        self,
        InstrumentId instrument_id,
        BookLevel level,
        dict kwargs=None,
    ) except *:
        """
        Subscribe to `OrderBook` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The order book instrument to subscribe to.
        level : BookLevel
            The order book level (L1, L2, L3).
        kwargs : dict, optional
            The keyword arguments for exchange specific parameters.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to order book deltas for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_order_book_delta[instrument_id] = None
        # Do nothing else for backtest

    cpdef void subscribe_quote_ticks(self, InstrumentId instrument_id) except *:
        """
        Subscribe to `QuoteTick` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to subscribe to.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to quote ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_quote_tick[instrument_id] = None
        # Do nothing else for backtest

    cpdef void subscribe_trade_ticks(self, InstrumentId instrument_id) except *:
        """
        Subscribe to `TradeTick` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to subscribe to.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_trade_tick[instrument_id] = None
        # Do nothing else for backtest

    cpdef void subscribe_bars(self, BarType bar_type) except *:
        """
        Subscribe to `Bar` data for the given bar type.

        Parameters
        ----------
        bar_type : BarType
            The bar type to subscribe to.

        """
        Condition.not_none(bar_type, "bar_type")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to bars for {bar_type} "
                f"(not connected).",
            )
            return

        self._feeds_bar[bar_type] = None

    cpdef void subscribe_instrument_status_updates(self, InstrumentId instrument_id) except *:
        """
        Subscribe to `InstrumentStatusUpdates` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to subscribe to.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument_status_update[instrument_id] = None
        # Do nothing else for backtest

    cpdef void subscribe_instrument_close_prices(self, InstrumentId instrument_id) except *:
        """
        Subscribe to `InstrumentClosePrice` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to subscribe to.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot subscribe to trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument_close_price[instrument_id] = None
        # Do nothing else for backtest

    cpdef void unsubscribe_instruments(self) except *:
        """
        Unsubscribe from `Instrument` data for the venue.

        """
        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from instruments (not connected).",
            )
            return

        self._feeds_instrument.clear()
        # Do nothing else for backtest

    cpdef void unsubscribe_instrument(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `Instrument` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from instrument for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument.discard(instrument_id)
        # Do nothing else for backtest

    cpdef void unsubscribe_order_book_deltas(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `OrderBookData` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The order book instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from order book deltas for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_order_book_delta.pop(instrument_id, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_order_book_snapshots(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `OrderBook` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The order book instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from order book snapshots for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_order_book_snapshot.pop(instrument_id, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_quote_ticks(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `QuoteTick` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from quote ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_quote_tick.pop(instrument_id, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_trade_ticks(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `TradeTick` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_trade_tick.pop(instrument_id, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_bars(self, BarType bar_type) except *:
        """
        Unsubscribe from `Bar` data for the given bar type.

        Parameters
        ----------
        bar_type : BarType
            The bar type to unsubscribe from.

        """
        Condition.not_none(bar_type, "bar_type")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from bars {bar_type} (not connected).",
            )
            return

        self._log.error(
            f"Cannot unsubscribe from externally aggregated bars "
            f"(backtesting only supports internal aggregation at this stage).",
        )

        self._feeds_bar.pop(bar_type, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_instrument_status_updates(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `InstrumentStatusUpdates` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument_status_update.pop(instrument_id, None)
        # Do nothing else for backtest

    cpdef void unsubscribe_instrument_close_prices(self, InstrumentId instrument_id) except *:
        """
        Unsubscribe from `InstrumentClosePrice` data for the given instrument ID.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument to unsubscribe from.

        """
        Condition.not_none(instrument_id, "instrument_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot unsubscribe from trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        self._feeds_instrument_close_price.pop(instrument_id, None)
        # Do nothing else for backtest

# -- REQUESTS --------------------------------------------------------------------------------------

    cpdef void request_quote_ticks(
        self,
        InstrumentId instrument_id,
        datetime from_datetime,  # Can be None
        datetime to_datetime,    # Can be None
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical quote ticks for the given parameters.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument ID for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data.
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned ticks.
        correlation_id : UUID
            The correlation ID for the request.

        """
        Condition.not_none(instrument_id, "instrument_id")
        Condition.not_none(correlation_id, "correlation_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot request quote ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        # Do nothing else for backtest

    cpdef void request_trade_ticks(
        self,
        InstrumentId instrument_id,
        datetime from_datetime,  # Can be None
        datetime to_datetime,    # Can be None
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical trade ticks for the given parameters.

        Parameters
        ----------
        instrument_id : InstrumentId
            The tick instrument ID for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data.
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned ticks.
        correlation_id : UUID
            The correlation ID for the request.

        """
        Condition.not_none(instrument_id, "instrument_id")
        Condition.not_negative_int(limit, "limit")
        Condition.not_none(correlation_id, "correlation_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(
                f"Cannot request trade ticks for {instrument_id} "
                f"(not connected).",
            )
            return

        # Do nothing else for backtest

    cpdef void request_bars(
        self,
        BarType bar_type,
        datetime from_datetime,  # Can be None
        datetime to_datetime,    # Can be None
        int limit,
        UUID correlation_id,
    ) except *:
        """
        Request historical bars for the given parameters from the data engine.

        Parameters
        ----------
        bar_type : BarType
            The bar type for the request.
        from_datetime : datetime, optional
            The specified from datetime for the data.
        to_datetime : datetime, optional
            The specified to datetime for the data. If None then will default
            to the current datetime.
        limit : int
            The limit for the number of returned bars.
        correlation_id : UUID
            The correlation ID for the request.

        """
        Condition.not_none(bar_type, "bar_type")
        Condition.not_negative_int(limit, "limit")
        Condition.not_none(correlation_id, "correlation_id")

        if not self.is_connected:  # Simulate connection behaviour
            self._log.error(f"Cannot request bars for {bar_type} (not connected).")
            return

        # Do nothing else for backtest
