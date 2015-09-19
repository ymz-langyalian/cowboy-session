标准rebar项目结构
使用说明：
	1,启动cowboy应用，指定middlewares：[cowboy_router, cowboy_session_middleware, cowboy_handler]
	cowboy:start_http(端口号，进程名称,[其他参数]， [{middlewares,[cowboy_router, cowboy_session_middleware, cowboy_handler]}]).
	
	2,指定cowboy_session存储为redis
	cowboy_session_config:update_storage(cowboy_session_storage_redis)

	3,配置redis连接池，连接池采用pooler,在sys.config中配置redis连接
	{pooler, [
        {pools, [
            [
                {name, eredis_master_pool},
                {group, eredis},
                {max_count, 30},
                {init_count, 5},
                {start_mfa, {eredis, start_link, ["127.0.0.1", 6379]}}
            ],
            [
                {name, eredis_slave_pool},
                {group, eredis},
                {max_count, 30},
                {init_count, 5},
                {start_mfa, {eredis, start_link, ["127.0.0.1", 6379]}}
            ]
        ]}
    	]}

	4,配置会话时间
	cowboy_session_config:set([{expire, 会话时间（单位为：秒）}])





























































