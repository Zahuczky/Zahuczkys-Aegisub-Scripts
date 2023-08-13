from collections import namedtuple
import io
import logging
import re

speedtesting = False

threads = 2

if not speedtesting:
    logging.basicConfig(format="%(relativeCreated)d %(message)s", level=logging.INFO)
    logger = logging.getLogger()
else:
    logging.basicConfig(format="%(relativeCreated)d %(message)s", level=logging.DEBUG)
    logger = logging.getLogger()
    log_stream = io.StringIO()
    stream_handler = logging.StreamHandler(log_stream)
    stream_handler.setFormatter(logging.Formatter("%(relativeCreated)d %(message)s"))
    stream_handler.setLevel(logging.DEBUG)
    logger.addHandler(stream_handler)

    logger.debug("Speedtesting enabled")

def speedtesting_result():
    log = log_stream.getvalue()

    data = {}
    first_load = None
    last_render = None
    loading = re.compile("(\d*) Loading frame (\d*)")
    rendering = re.compile("(\d*) Rendering frame (\d*)")

    for line in log.splitlines():
        if (match := loading.match(line)):
            first_load = first_load or (int(match.group(2)), int(match.group(1)))
            if int(match.group(2)) not in data:
                data[int(match.group(2))] = [None, None]
            data[int(match.group(2))][0] = int(match.group(1))
        elif (match := rendering.match(line)):
            last_render = (int(match.group(2)), int(match.group(1)))
            if int(match.group(2)) not in data:
                data[int(match.group(2))] = [None, None]
            data[int(match.group(2))][1] = int(match.group(1))

    logger.debug(f"Frame: {last_render[0] - first_load[0] + 1}")
    logger.debug(f"Time: {(last_render[1] - first_load[1]) / 1000}")
    logger.debug(f"Fps: {(last_render[0] - first_load[0] + 1) / (last_render[1] - first_load[1]) * 1000}")

    response_time = 0
    response_time_divider = 0
    for _, v in data.items():
        if v[0] and v[1]:
            response_time += v[1] - v[0]
            response_time_divider += 1

    logger.debug(f"Response time: {response_time / response_time_divider / 1000}")

Settings = namedtuple("Settings", ["l_threshold", "c_threshold"])
