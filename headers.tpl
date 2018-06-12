# This file auto-generated by `generate_headers.py`.
# Do not modify this file directly.
import ctypes


# constants related to ExtendedMessageHeader
MAX_16BIT = 0xffff
MARKER1 = 0xffff
MARKER2 = 0x0000


class _BaseMessageHeader(ctypes.BigEndianStructure):
    # just to define a nice repr
    def __repr__(self):
        d = [(field, getattr(self, field)) for field, _type in self._fields_]
        formatted_args = ", ".join(["{!s}={!r}".format(k, v) for k, v in d])
        return "{}({})".format(type(self).__name__, formatted_args)


class MessageHeader(_BaseMessageHeader):
    """
    A Structure for the Header of a Channel Access command.

    The specification is documented at:
    http://www.aps.anl.gov/epics/base/R3-16/0-docs/CAproto/index.html#_messages
    """
    _fields_ = [("command", ctypes.c_uint16),
                ("payload_size", ctypes.c_uint16),
                ("data_type", ctypes.c_uint16),
                ("data_count", ctypes.c_uint16),
                ("parameter1", ctypes.c_uint32),
                ("parameter2", ctypes.c_uint32),
               ]


class ExtendedMessageHeader(_BaseMessageHeader):
    """
    A Structure for the Extended Header of a Channel Access command.

    The specification is documented at:
    http://www.aps.anl.gov/epics/base/R3-16/0-docs/CAproto/index.html#_messages
    """
    def __init__(self, command, payload_size, data_type, data_count,
                 parameter1, parameter2):
        super().__init__(command, MARKER1, data_type, MARKER2, parameter1,
                         parameter2, payload_size, data_count)

    _fields_ = [("command", ctypes.c_uint16),
                ("marker1", ctypes.c_uint16),
                ("data_type", ctypes.c_uint16),
                ("marker2", ctypes.c_uint16),
                ("parameter1", ctypes.c_uint32),
                ("parameter2", ctypes.c_uint32),
                ("payload_size", ctypes.c_uint32),
                ("data_count", ctypes.c_uint32),
               ]


{% for command in commands %}
def {{command.name}}Header({{ command.input_params|map('attr', 'field')|join(', ') }}):
    """
    Construct a ``MessageHeader`` for a {{command.name}} command.

    {{command.description.strip().split('\n')|join(' ')|replace('\t', ' ')|replace('   ', ' ')|wordwrap(75)|indent(4)}}

    Parameters
    ----------
{% for param in command.input_params %}
    {{ param.field }} : integer
        {{ param.description.strip().split('\n')|join(' ')|replace('\t', ' ')|replace('   ', ' ')|wordwrap(75)|indent(4) }}
{% endfor %}
    """
    {% if command.struct_args[3] in ('data_count', ) or command.struct_args[1] in ('payload_size', ) -%}
    struct_args = ({{ command.struct_args|join(', ') }})
    # If payload_size or data_count cannot fit into a 16-bit integer, use the
    # extended header.
    return (ExtendedMessageHeader(*struct_args)
            if any((
            {%- for arg in (command.struct_args[1], command.struct_args[3]) if arg != 0 -%}
                {{ arg }} > 0xffff, {% endfor -%}
            ))
            else MessageHeader(*struct_args))
    {%- else -%}
    return MessageHeader({{ command.struct_args|join(', ') }})
    {%- endif %}

{% endfor %}
# This file auto-generated by `generate_headers.py`.
# Do not modify this file directly.
# (end of auto-generated code)