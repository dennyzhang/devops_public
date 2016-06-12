Dump DB Summary
===============
- How many tables
- How many records

Support typical major SQL/NoSQL DB by plugins

To support more DB engine, you need implement:
- bash function dump_${db_name}_summary
- Provide a conf file ${db_name}.cfg, to pass critical config parameters like db credentials.