import re
import logging

import curio
import asks  # for http requests through curio

import urllib.request
import urllib.parse
from caproto.benchmarking import set_logging_level
from caproto.curio.server import start_server
from caproto.curio.high_level_server import pvproperty, PVGroupBase


async def convert_currency(amount, from_currency, to_currency):
    'Perform the currency conversion'
    params = urllib.parse.urlencode({'a': amount,
                                     'from': from_currency,
                                     'to': to_currency,
                                     })
    resp = await asks.get('https://finance.google.com/finance/'
                          'converter?' + params)
    m = re.search(r'<span class=bld>([^ ]*)',
                  resp.content.decode('latin-1'))
    converted = float(m.groups()[0])
    print(f'Converted {amount} {from_currency} to {to_currency} = {converted}')
    return converted


class CurrencyPollingIOC(PVGroupBase):
    from_currency = pvproperty(value=['BTC'])
    to_currency = pvproperty(value=['USD'])
    amount = pvproperty(value=[1])

    update_rate = pvproperty(value=[3.0])
    converted = pvproperty(value=[0.0])

    @converted.startup
    async def converted(self, instance, async_lib):
        'Periodically update the value'
        print('Starting currency conversion')
        while True:
            # perform the conversion
            converted_amount = await convert_currency(
                amount=self.amount.value[0],
                from_currency=self.from_currency.value[0],
                to_currency=self.to_currency.value[0],
            )

            # update the ChannelData instance and notify any subscribers
            await instance.write(value=[converted_amount])

            # Let the async library wait for the next iteration
            await async_lib.sleep(self.update_rate.value[0])


def main(prefix, macros):
    set_logging_level(logging.DEBUG)
    asks.init('curio')
    ioc = CurrencyPollingIOC(prefix=prefix, macros=macros)
    curio.run(start_server, ioc.pvdb)


if __name__ == '__main__':
    main(prefix='currency:', macros={})
