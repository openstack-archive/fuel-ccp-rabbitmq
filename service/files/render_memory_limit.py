#!/usr/bin/env python

import argparse
import os

from jinja2 import Environment, FileSystemLoader

def render_jinja2_template(src, dst, context):
    path, filename = os.path.split(src)
    content = Environment(
                    loader=FileSystemLoader(path)
                    ).get_template(filename).render(context)
    with open(dst, 'w') as destination:
        destination.write(content)


def _memory_limit(ratio):
    MEMORY_LIMIT='/sys/fs/cgroup/memory/memory.limit_in_bytes'
    with open(MEMORY_LIMIT, 'r') as limit_config:
        limit = int(limit_config.read())
    return {'vm_memory_high_watermark': int(limit*ratio)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', type=str)
    parser.add_argument('--dst', type=str)
    parser.add_argument('--ratio', default=0.75, type=float)
    args = parser.parse_args()
    render_jinja2_template(args.src, args.dst, _memory_limit(args.ratio))
