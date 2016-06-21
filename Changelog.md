### Changes from 0.1.1 to ?.?.?

* handle CLI (arguments) with Thor
* add a global/root scope: variables can also be defined at top level

### Changes from 0.1.0 to 0.1.1

* force encoding to ASCII-8BIT of data send to stdin through ssh

### Changes from 0.0.1 to 0.1.0

* configuration format changed (XML => Ruby)
* shell completion added
* reload command added
* alternate configuration file can be specified through environment variable CINDY_CONF (eg, with (ba|k|z)sh: `CINDY_CONF=alternate/path cindy`)
* all commands which change internal state removed
