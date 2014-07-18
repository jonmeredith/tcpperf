%% Server - consume all TCP packets received
-module(tcpperf_svr).
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
%% internal
-export([do_recv/1]).

-behavior(gen_server).

-record(sample, {cnt = 0, oct = 0, at = os:timestamp()}).
-record(state, {socket, pid, last, first}).

start_link(S) ->
    gen_server:start_link(?MODULE, [S], []).

init([S]) ->
    {Pid, _MRef} = spawn_monitor(?MODULE, do_recv, [S]),
    schedule_tick(),
    io:format("~p: starting\n", [self()]),
    First = #sample{},
    {ok, #state{pid = Pid, socket = S, last = First, first = First}}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(tick, State = #state{socket = S, last = Last}) ->
    schedule_tick(),
    {noreply, State#state{last = report(S, Last)}};
handle_info({'DOWN', _MRef, process, _Obj, _Info}, State = #state{socket = S, first = First}) ->
    report(S, First),
    io:format("~p: closed\n", [self()]),
    {stop, normal, State};
handle_info(_Msg, State) ->
    error_logger:info_msg("Unknown msg: ~p", [_Msg]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


report(S, #sample{cnt = LCnt, oct = LOct, at = LWhen}) ->
    {ok, [{recv_cnt, NCnt}, {recv_oct, NOct}]} = inet:getstat(S, [recv_cnt, recv_oct]),
    NWhen = os:timestamp(),
    DCnt = NCnt - LCnt,
    DOct = NOct - LOct,
    DWhen = timer:now_diff(NWhen, LWhen) / 1000000.0,
    io:format("~p: cnt/sec=~p bit/sec=~p over ~p seconds\n",
              [self(), DCnt / DWhen, DOct / DWhen, DWhen]),
    #sample{cnt = NCnt, oct = NOct, at = NWhen}.


schedule_tick() ->
    timer:send_after(5000, tick).

%% Receive loop on helper process
do_recv(Sock) ->
           case gen_tcp:recv(Sock, 0) of
               {ok, _B} ->
                   do_recv(Sock);
               {error, closed} ->
                   ok
           end.

