"""
Produce traffic on the Orcale DB in order to test the SymmetricsDS middleware

SYNOPSIS:

symmetricsds_test.py --username 'OPS$CREDISEG' --password **** \
    --hostname sicyc-dev-src-replica20221215172414176100000002.cv3bqn9qsiga.eu-central-1.rds.amazonaws.com --port 1527 \
    --db-name SPSOL01 --row-count 100000

"""
import datetime
import logging
import sys
import time
from argparse import ArgumentParser, RawTextHelpFormatter

import oracledb

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s | %(levelname)-8s | %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger()


class TimerError(Exception):
    """A custom exception used to report errors in use of Timer class"""


class Timer:
    def __init__(self, text="Elapsed time: {:0.8f} seconds", logger=print):
        self._start_time = None
        self._text = text
        self._logger = logger

    def start(self):
        """Start a new timer"""
        if self._start_time is not None:
            raise TimerError(f"Timer is running. Use .stop() to stop it")
        self._start_time = time.perf_counter()

    def stop(self):
        """Stop the timer, and report the elapsed time"""
        if self._start_time is None:
            raise TimerError(f"Timer is not running. Use .start() to start it")
        elapsed_time = time.perf_counter() - self._start_time
        self._start_time = None
        if self._logger:
            self._logger(self._text.format(elapsed_time))
        return elapsed_time


def get_db_connection(args):
    return oracledb.connect(
        user=args.username,
        password=args.password,
        dsn=f"{args.hostname}:{args.port}/{args.db_name}")


def write(args):
    """Produces traffic according to the user requirements

    Args:
        args (_type_): _description_
    """
    connection = get_db_connection(args)
    logger.info("Successfully connected to Oracle Database")
    cursor = connection.cursor()
    field_size = 128
    value_frgt = f"LPAD(DBMS_RANDOM.STRING('U', 128), {field_size})"
    if args.table == "PERF_MEDIUM":
        field_size = 4000
        value_frgt = f"LPAD(DBMS_RANDOM.STRING('U', 128), {field_size})"
    elif args.table == "PERF_LARGE":
        field_size = 32767
        value_frgt = f"TO_CLOB(LPAD(DBMS_RANDOM.STRING('U', 128), {field_size}))"
    logger.info(f"Inserting {args.row_count} rows in table {args.table} ...")
    t = Timer(
        text=("Inserted %d row in {:.1f} seconds." % args.row_count), logger=logger.info)
    t.start()
    commit = 0
    if args.commit:
        commit = 1
    cursor.execute(f"""
        BEGIN
	        FOR I IN 1..{args.row_count} LOOP
                INSERT INTO {args.table} (TEXT) VALUES ({value_frgt});
                IF ({commit} = 1) THEN IF (MOD (I, 1000) = 0) THEN COMMIT; END IF; END IF;
            END LOOP;
        END;""")
    connection.commit()
    t.stop()
    return 0


def monitor(args):
    """Evaluates the number of records in the given table.

    Args:
        args (_type_): _description_
    """
    connection = get_db_connection(args)
    logger.info("Successfully connected to Oracle Database")
    cursor = connection.cursor()
    with open(f"{args.table}.csv", "a") as file:
        file.write(f"Time;Count\n")
    last_count = 0
    while True:
        try:
            cursor.execute(f"SELECT COUNT(1) AS COUNT FROM {args.table}")
            columns = [col[0] for col in cursor.description]
            cursor.rowfactory = lambda *args: dict(zip(columns, args))
            row = cursor.fetchone()
            if row['COUNT'] != last_count:
                last_count = row['COUNT']
                logger.info(f"Table {args.table} has {last_count} register(s)")
                if args.csv:
                    now = datetime.datetime.now()
                    with open(f"{args.table}.csv", "a") as file:
                        file.write(f"{now.strftime('%X')};{last_count}\n")
        except Exception:
            logging.error(e, stack_info=True)
        time.sleep(0.1)
    return 0 # Only exit with Ctrl+C


def parse_command_line():
    parser = ArgumentParser(prog='symmetricsds_produce.py',
                            description=__doc__, formatter_class=RawTextHelpFormatter)
    parser.add_argument(
        '--debug', action="store_true", help='Run the program in debug mode', required=False, default=False)
    parser.add_argument(
        '--quiet', action="store_true", help='Run the program in quiet mode', required=False, default=False)
    parser.add_argument(
        '--username', help='The username to access the DB', required=True)
    parser.add_argument(
        '--password', help='The password to access the DB', required=True)
    parser.add_argument(
        '--hostname', help="The hostname of the DB to connect to", required=True, )
    parser.add_argument(
        '--port', help='The port on which to connect to the DB', required=False, default=1527)
    parser.add_argument(
        '--db-name', help="The name of the DB to connect to", required=True)
    parser.add_argument('--action', help="Select the action you want to perform",
                        required=False, default="write", choices=['write', 'monitor'])
    parser.add_argument('--table', help="When action is set to 'write', select the table on which to test the performance",
                        required=False, default="PERF_SMALL", choices=['PERF_SMALL', 'PERF_MEDIUM', 'PERF_LARGE'], )
    parser.add_argument('--row-count', type=int,
                        help="When action is set to 'write', the number of row to insert", required=False, default=100)
    parser.add_argument('--commit', action="store_true", help="Whether to use intermediary commits",
                        required=False, default=False)
    parser.add_argument(
        '--csv', action="store_true", help='Output to CSV in monitor mode', required=False, default=False)
    return parser.parse_args()


def main():
    args = parse_command_line()
    try:
        if args.debug:
            logger.setLevel(logging.DEBUG)
        if args.quiet:
            logger.setLevel(logging.ERROR)
        if args.action == "write":
            return write(args)
        elif args.action == "monitor":
            return monitor(args)
        else:
            raise Exception
    except Exception as e:
        logging.error(e, stack_info=True)
        return 1


if __name__ == '__main__':
    sys.exit(main())
