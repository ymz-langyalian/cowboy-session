%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 六月 2015 下午1:33
%%%-------------------------------------------------------------------
-module(cowboy_session_storage_redis).

-behaviour(cowboy_session_storage).
%% API
-export([
    start_link/0,
    new/1,
    set/3,
    get/3,
    delete/1,
    delete/2,
    stop/1
]).

-behaviour(gen_server).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).


-record(state, {}).

-define(CONFIG, cowboy_session_config).
-define(Master_Pool, eredis_master_pool).
-define(Slave_Pool, eredis_slave_pool).
%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

new(SID) ->
    gen_server:cast(?MODULE, {new, SID}).

set(SID, Key, Value) ->
    gen_server:cast(?MODULE, {set, SID, Key, Value}).

get(SID, Key, Default) ->
    gen_server:call(?MODULE, {get, SID, Key, Default}).

delete(SID) ->
    gen_server:cast(?MODULE, {delete, SID}).

delete(SID, Key) ->
    gen_server:cast(?MODULE, {delete, SID, Key}).

stop(New_storage) ->
    gen_server:cast(?MODULE, {stop, New_storage}).


%%%===================================================================
%%% Gen_server callbacks
%%%===================================================================

init([]) ->
    State = #state{},
    {ok, State}.

handle_call({get, SID, Key, Default}, _From, State) ->
    Reply = case lib_pooler:use_member(fun(EredisPid) ->
        case eredis:q(EredisPid, ["EXISTS", prefixed(SID)]) of
            {ok, <<"1">>} ->
                eredis:q(EredisPid, ["EXPIRE", prefixed(SID), ?CONFIG:get(expire)]);
            _ ->
                ignore
        end,
        eredis:q(EredisPid, ["HMGET", prefixed(SID), Key]) end, ?Slave_Pool) of
                [] -> Default;
                Other -> Other
            end,
    {reply, Reply, State};

handle_call(_, _, State) -> {reply, ignored, State}.


handle_cast({new, SID}, State) ->
    lib_pooler:use_member(fun(EredisPid) -> eredis:qp(EredisPid, [["HSET", prefixed(SID), "SID", SID],
        ["EXPIRE", prefixed(SID), ?CONFIG:get(expire)]]) end, ?Master_Pool),
    {noreply, State};

handle_cast({set, SID, Key, Value}, State) ->
    lib_pooler:use_member(fun(EredisPid) -> eredis:q(EredisPid, ["HSET", prefixed(SID), Key, Value]) end, ?Master_Pool),
    {noreply, State};

handle_cast({delete, SID}, State) ->
    lib_pooler:use_member(fun(EredisPid) -> eredis:q(EredisPid, ["DEL", prefixed(SID)]) end, ?Master_Pool),
    {noreply, State};

handle_cast({delete, SID, Key}, State) ->
    lib_pooler:use_member(fun(EredisPid) -> eredis:q(EredisPid, ["HDEL", prefixed(SID), Key]) end, ?Master_Pool),
    {noreply, State};

handle_cast({stop, _New_storage}, State) ->
    {stop, normal, State};

handle_cast(_, State) -> {noreply, State}.


handle_info(_, State) -> {noreply, State}.


terminate(_Reason, _) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.



prefixed(SID) ->
    prefix() ++ ":" ++ lib_util:to_list(SID).


prefix() ->
    case os:getenv("REDIS_PREFIX") of
        false -> "cowboy_session";
        P -> P
    end.

