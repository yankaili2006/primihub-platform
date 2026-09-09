package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.sys.param.AgentParam;
import com.primihub.biz.entity.sys.param.ServerParam;
import com.primihub.biz.entity.sys.po.Agent;
import com.primihub.biz.entity.sys.po.Server;
import com.primihub.biz.entity.sys.po.ServerAgent;
import com.primihub.biz.entity.sys.po.ServerArtifact;
import com.primihub.biz.entity.sys.po.ServerModel;
import com.primihub.biz.entity.sys.po.ServerNode;
import com.primihub.biz.entity.sys.po.ServerResource;
import com.primihub.biz.entity.sys.vo.AgentVO;
import com.primihub.biz.entity.sys.vo.ServerVO;
import com.primihub.biz.repository.primarydb.sys.ServerPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.ServerSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class ServerService {

    @Autowired
    private ServerPrimarydbRepository serverPrimarydbRepository;

    @Autowired
    private ServerSecondarydbRepository serverSecondarydbRepository;

    // ============================================================
    // Server CRUD
    // ============================================================

    public BaseResultEntity getServerPage(ServerParam param) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("serverName", param.getServerName());
            params.put("serverType", param.getServerType());
            params.put("serverStatus", param.getServerStatus());
            params.put("offset", param.getOffset());
            params.put("pageSize", param.getPageSize());

            int total = serverSecondarydbRepository.selectServerCount(params);
            PageParam pageParam = new PageParam(param.getPageNo(), param.getPageSize());
            pageParam.initItemTotalCount((long) total);

            List<ServerVO> list = serverSecondarydbRepository.selectServerList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询服务器列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity getServerDetail(Long serverId) {
        try {
            Server server = serverSecondarydbRepository.selectServerById(serverId);
            if (server == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "服务器不存在");
            }
            ServerVO vo = new ServerVO();
            BeanUtils.copyProperties(server, vo);
            vo.setResources(serverSecondarydbRepository.selectResourcesByServerId(serverId));
            vo.setModels(serverSecondarydbRepository.selectModelsByServerId(serverId));
            vo.setArtifacts(serverSecondarydbRepository.selectArtifactsByServerId(serverId));
            vo.setNodes(serverSecondarydbRepository.selectNodesByServerId(serverId));
            vo.setAgents(serverSecondarydbRepository.selectAgentsByServerId(serverId));
            return BaseResultEntity.success(vo);
        } catch (Exception e) {
            log.error("查询服务器详情失败，serverId={}", serverId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity createServer(Server server) {
        try {
            serverPrimarydbRepository.insertServer(server);
            return BaseResultEntity.success(server.getServerId());
        } catch (Exception e) {
            log.error("创建服务器失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    public BaseResultEntity updateServer(Server server) {
        try {
            Server existing = serverSecondarydbRepository.selectServerById(server.getServerId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "服务器不存在");
            }
            serverPrimarydbRepository.updateServer(server);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("更新服务器失败，serverId={}", server.getServerId(), e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    public BaseResultEntity deleteServer(Long serverId) {
        try {
            Server existing = serverSecondarydbRepository.selectServerById(serverId);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "服务器不存在");
            }
            serverPrimarydbRepository.deleteServerById(serverId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("删除服务器失败，serverId={}", serverId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ============================================================
    // Agent CRUD
    // ============================================================

    public BaseResultEntity getAgentPage(AgentParam param) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("agentName", param.getAgentName());
            params.put("agentType", param.getAgentType());
            params.put("status", param.getStatus());
            params.put("offset", param.getOffset());
            params.put("pageSize", param.getPageSize());

            int total = serverSecondarydbRepository.selectAgentCount(params);
            PageParam pageParam = new PageParam(param.getPageNo(), param.getPageSize());
            pageParam.initItemTotalCount((long) total);

            List<AgentVO> list = serverSecondarydbRepository.selectAgentList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询智能体列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    public BaseResultEntity createAgent(Agent agent) {
        try {
            serverPrimarydbRepository.insertAgent(agent);
            return BaseResultEntity.success(agent.getAgentId());
        } catch (Exception e) {
            log.error("创建智能体失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "创建失败");
        }
    }

    public BaseResultEntity updateAgent(Agent agent) {
        try {
            Agent existing = serverSecondarydbRepository.selectAgentById(agent.getAgentId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "智能体不存在");
            }
            serverPrimarydbRepository.updateAgent(agent);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("更新智能体失败，agentId={}", agent.getAgentId(), e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    public BaseResultEntity deleteAgent(Long agentId) {
        try {
            Agent existing = serverSecondarydbRepository.selectAgentById(agentId);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "智能体不存在");
            }
            serverPrimarydbRepository.deleteAgentById(agentId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("删除智能体失败，agentId={}", agentId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    // ============================================================
    // Association operations
    // ============================================================

    public BaseResultEntity bindResource(Long serverId, Long resourceId) {
        try {
            ServerResource sr = new ServerResource();
            sr.setServerId(serverId);
            sr.setResourceId(resourceId);
            serverPrimarydbRepository.insertServerResource(sr);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("绑定数据资源失败，serverId={}, resourceId={}", serverId, resourceId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "绑定失败");
        }
    }

    public BaseResultEntity unbindResource(Long serverId, Long resourceId) {
        try {
            serverPrimarydbRepository.deleteServerResource(serverId, resourceId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("解绑数据资源失败，serverId={}, resourceId={}", serverId, resourceId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解绑失败");
        }
    }

    public BaseResultEntity bindModel(Long serverId, Long modelId, String modelVersion) {
        try {
            ServerModel sm = new ServerModel();
            sm.setServerId(serverId);
            sm.setModelId(modelId);
            sm.setModelVersion(modelVersion);
            serverPrimarydbRepository.insertServerModel(sm);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("绑定模型失败，serverId={}, modelId={}", serverId, modelId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "绑定失败");
        }
    }

    public BaseResultEntity unbindModel(Long serverId, Long modelId) {
        try {
            serverPrimarydbRepository.deleteServerModel(serverId, modelId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("解绑模型失败，serverId={}, modelId={}", serverId, modelId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解绑失败");
        }
    }

    public BaseResultEntity bindArtifact(Long serverId, Long artifactId) {
        try {
            ServerArtifact sa = new ServerArtifact();
            sa.setServerId(serverId);
            sa.setArtifactId(artifactId);
            serverPrimarydbRepository.insertServerArtifact(sa);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("绑定模型产物失败，serverId={}, artifactId={}", serverId, artifactId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "绑定失败");
        }
    }

    public BaseResultEntity unbindArtifact(Long serverId, Long artifactId) {
        try {
            serverPrimarydbRepository.deleteServerArtifact(serverId, artifactId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("解绑模型产物失败，serverId={}, artifactId={}", serverId, artifactId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解绑失败");
        }
    }

    public BaseResultEntity bindNode(Long serverId, Long nodeId, String accessType, Integer isPrimary) {
        try {
            ServerNode sn = new ServerNode();
            sn.setServerId(serverId);
            sn.setNodeId(nodeId);
            sn.setAccessType(accessType);
            sn.setIsPrimary(isPrimary == null ? 0 : isPrimary);
            serverPrimarydbRepository.insertServerNode(sn);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("绑定节点失败，serverId={}, nodeId={}", serverId, nodeId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "绑定失败");
        }
    }

    public BaseResultEntity unbindNode(Long serverId, Long nodeId) {
        try {
            serverPrimarydbRepository.deleteServerNode(serverId, nodeId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("解绑节点失败，serverId={}, nodeId={}", serverId, nodeId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解绑失败");
        }
    }

    public BaseResultEntity bindAgent(Long serverId, Long agentId) {
        try {
            ServerAgent sa = new ServerAgent();
            sa.setServerId(serverId);
            sa.setAgentId(agentId);
            serverPrimarydbRepository.insertServerAgent(sa);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("绑定智能体失败，serverId={}, agentId={}", serverId, agentId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "绑定失败");
        }
    }

    public BaseResultEntity unbindAgent(Long serverId, Long agentId) {
        try {
            serverPrimarydbRepository.deleteServerAgent(serverId, agentId);
            return BaseResultEntity.success(null);
        } catch (Exception e) {
            log.error("解绑智能体失败，serverId={}, agentId={}", serverId, agentId, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "解绑失败");
        }
    }
}
