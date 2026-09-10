package com.primihub.biz.entity.sys.param;

import com.primihub.biz.entity.data.req.PageReq;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

@Data
@ApiModel("智能体查询参数")
public class AgentParam extends PageReq {
    @ApiModelProperty("智能体名称（模糊）")
    private String agentName;
    @ApiModelProperty("智能体类型")
    private String agentType;
    @ApiModelProperty("状态: 0停用 1启用")
    private Integer status;
}
