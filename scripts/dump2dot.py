# Copyright (C) 2012 Dave Abrahams <dave@boostpro.com>
#
# Distributed under the Boost Software License, Version 1.0.  See
# accompanying file LICENSE_1_0.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt

import glob, sys
from subprocess import check_output, check_call, Popen, PIPE
from xml.etree.cElementTree import ElementTree, Element
from path import Path
from read_dumps import read_dumps
from depgraph import *
from transitive import *
from display_graph import *

colors=('red','green','orange', 'blue', 'indigo', 'violet')

def first(seq):
    return iter(seq).next()

def run(dump_dir=None):
    g = dumps = read_dumps(dump_dir)

    # find all strongly-connected components
    from SCC import SCC
    sccs = SCC(str, lambda i: successors(g, i)).getsccs(g)
    # map each vertex to a scc set
    scc = {}
    for component in sccs:
        s = set(component)
        for u in s:
            scc[u] = s

    long_sccs = [s for s in sccs if len(s) > 1]
    print 'long_sccs=', long_sccs

    # color each vertex in an SCC of size > 1 according to its SCC
    color = {}
    for i,s in enumerate(long_sccs):
        for u in s:
            color[u] = colors[i]

    V = g #set(u for u in g if successors(g,u))
    direct_graph = to_mutable_graph(g, direct_successors, V.__contains__)
    full_graph = to_mutable_graph(g, vertex_filter=V.__contains__)

    t_redux = to_mutable_graph(g, usage_successors, vertex_filter=V.__contains__)
    inplace_transitive_reduction(t_redux)

    class Format(object):
        def vertex_attributes(self, s):
            ret = ['color='+color[s]] if s in color else []
            ret += ['fontsize=9']
            if dumps[s].find('libraries/library') is not None:
                ret+=['shape=box3d','style=bold']
            return ret

        def edge_attributes(self, s, t):
            if t in direct_graph[s]:
                return ['style=bold']
            elif t in t_redux[s]:
                return ['style=dashed','arrowhead=open','color=blue']
            else:
                return ['style=dotted','color=gray']

    show_digraph(full_graph, formatter=Format(), ranksep=1.8, splines='true', layout='dot')

if __name__ == '__main__':
    argv = sys.argv
    run(dump_dir=Path(argv[1]) if len(argv) > 1 else None)
