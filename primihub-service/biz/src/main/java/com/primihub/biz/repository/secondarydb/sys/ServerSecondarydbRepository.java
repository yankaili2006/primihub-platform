package com.primihub.biz.repository.secondarydb.sys;

import com.primihub.biz.entity.sys.po.Agent;
import com.primihub.biz.entity.sys.po.Server;
import com.primihub.biz.entity.sys.vo.AgentVO;
import com.primihub.biz.entity.sys.vo.ServerAgentVO;
import com.primihub.biz.entity.sys.vo.ServerArtifactVO;
import com.primihub.biz.entity.sys.vo.ServerModelVO;
import com.primihub.biz.entity.sys.vo.ServerNodeVO;
import com.primihub.biz.entity.sys.vo.ServerResourceVO;
import com.primihub.biz.entity.sys.vo.ServerVO;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * Server模块读库Repository（使用secondarydb数据源）
 */
@Repository
public interface ServerSecondarydbRepository {

    // ===== Server queries =====

    List<ServerVO> selectServerList(Map<String, Object> params);

    Integer selectServerCount(Map<String, Object> params);

    Server selectServerById(@Param("serverId") Long serverId);

    // ===== Agent queries =====

    List<AgentVO> selectAgentList(Map<String, Object> params);

    Integer selectAgentCount(Map<String, Object> params);

    Agent selectAgentById(@Param("agentId") Long agentId);

    // ===== Association queries (used in detail view) =====

    List<ServerResourceVO> selectResourcesByServerId(@Param("serverId") Long serverId);

    List<ServerModelVO> selectModelsByServerId(@Param("serverId") Long serverId);

    List<ServerArtifactVO> selectArtifactsByServerId(@Param("serverId") Long serverId);

    List<ServerNodeVO> selectNodesByServerId(@Param("serverId") Long serverId);

    List<ServerAgentVO> selectAgentsByServerId(@Param("serverId") Long serverId);
}
