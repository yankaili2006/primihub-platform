package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.Agent;
import com.primihub.biz.entity.sys.po.Server;
import com.primihub.biz.entity.sys.po.ServerAgent;
import com.primihub.biz.entity.sys.po.ServerArtifact;
import com.primihub.biz.entity.sys.po.ServerModel;
import com.primihub.biz.entity.sys.po.ServerNode;
import com.primihub.biz.entity.sys.po.ServerResource;
import org.apache.ibatis.annotations.Param;

/**
 * Server模块写库Repository（使用primarydb数据源）
 */
public interface ServerPrimarydbRepository {

    // ===== Server CRUD =====

    int insertServer(Server server);

    int updateServer(Server server);

    /** 软删除服务器（设置is_del=1） */
    int deleteServerById(@Param("serverId") Long serverId);

    // ===== Agent CRUD =====

    int insertAgent(Agent agent);

    int updateAgent(Agent agent);

    int deleteAgentById(@Param("agentId") Long agentId);

    // ===== Association tables =====

    int insertServerResource(ServerResource serverResource);

    int deleteServerResource(@Param("serverId") Long serverId, @Param("resourceId") Long resourceId);

    int insertServerModel(ServerModel serverModel);

    int deleteServerModel(@Param("serverId") Long serverId, @Param("modelId") Long modelId);

    int insertServerArtifact(ServerArtifact serverArtifact);

    int deleteServerArtifact(@Param("serverId") Long serverId, @Param("artifactId") Long artifactId);

    int insertServerNode(ServerNode serverNode);

    int deleteServerNode(@Param("serverId") Long serverId, @Param("nodeId") Long nodeId);

    int insertServerAgent(ServerAgent serverAgent);

    int deleteServerAgent(@Param("serverId") Long serverId, @Param("agentId") Long agentId);
}
