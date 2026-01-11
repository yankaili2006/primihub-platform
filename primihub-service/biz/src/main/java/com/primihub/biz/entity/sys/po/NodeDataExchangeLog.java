package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.util.Date;

/**
 * 节点数据交换日志实体类
 */
@Data
public class NodeDataExchangeLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 交换ID(UUID)
     */
    private String exchangeId;

    /**
     * 源节点ID
     */
    private String sourceOrganId;

    /**
     * 源节点名称
     */
    private String sourceOrganName;

    /**
     * 目标节点ID
     */
    private String targetOrganId;

    /**
     * 目标节点名称
     */
    private String targetOrganName;

    /**
     * 交换类型: project_sync(项目同步), model_sync(模型同步), resource_copy(资源复制)
     */
    private String exchangeType;

    /**
     * 数据类型: project, model, resource
     */
    private String dataType;

    /**
     * 数据ID
     */
    private String dataId;

    /**
     * 数据名称
     */
    private String dataName;

    /**
     * 数据大小(字节)
     */
    private Long dataSize;

    /**
     * 状态: 0=待处理, 1=成功, 2=失败, 3=部分成功
     */
    private Integer status;

    /**
     * 错误信息
     */
    private String errorMsg;

    /**
     * 重试次数
     */
    private Integer retryCount;

    /**
     * 开始时间
     */
    private Date startedAt;

    /**
     * 完成时间
     */
    private Date completedAt;

    /**
     * 持续时间(毫秒)
     */
    private Long durationMs;

    /**
     * 删除标记(0-未删除 1-已删除)
     */
    private Integer isDel;

    /**
     * 创建时间
     */
    private Date createDate;
}
