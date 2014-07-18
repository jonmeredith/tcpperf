-module(tcpperf_svr_listener).
-behavior(gen_server).
-export([start_link/0]).
-export([do_acceptor/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {lsock}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, Port} = application:get_env(port),
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, 0},
                                        {active, false}]),
    spawn_link(?MODULE, do_acceptor, [LSock]),
    {ok, #state{lsock = LSock}}.


handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {ok, State}.

handle_info(_Msg, State) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

do_acceptor(LSock) ->
    %%error_logger:info_msg("Acceptor waiting for new connection"),
    {ok, Sock} = gen_tcp:accept(LSock),
    %%error_logger:info_msg("Acceptor accepted ~p", [Sock]),
    {ok, Pid} = tcpperf_svr_sup:start_socket(Sock),
    ok = gen_tcp:controlling_process(Sock, Pid), % yes, there's a race
    do_acceptor(LSock).
