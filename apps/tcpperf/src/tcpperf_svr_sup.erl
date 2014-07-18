-module(tcpperf_svr_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).
-export([start_socket/1]).

start_socket(S) ->
    supervisor:start_child(?MODULE, [S]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    {ok,
     {{simple_one_for_one, 10, 10},
      [{undefined,
        {tcpperf_svr, start_link, []},
        temporary, brutal_kill, worker, [tcpperf_svr_sup]}]}}.
